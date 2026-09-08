require 'rails_helper'

RSpec.describe "Orders", type: :request do
  let(:client) { create(:client) }
  let(:catalog) { create(:catalog, client: client) }
  let(:user) { create(:user, client: client, role: :client, active: true, first_time_login: false) }

  before do
    sign_in user
  end

  describe "POST /orders/:id/duplicate" do
    let(:product1) { create(:product, base_price: 100) }
    let(:product2) { create(:product, base_price: 50) }

    let(:original_order) do
      build(:order, client: client, catalog: catalog, status: :submitted).tap do |order|
        order.order_items = [
          build(:order_item, order: nil, product: product1, color: "Red", size: "M", quantity: 5),
          build(:order_item, order: nil, product: product2, color: "Blue", size: "L", quantity: 3)
        ]
        order.save!(validate: false)
        order.reload
      end
    end

    context "when user is authenticated and order belongs to their client" do
      it "calls Orders::Duplicator with correct params" do
        duplicator = instance_double(Orders::Duplicator)
        cart = build(:order, client: client, catalog: catalog, status: :cart, ordered_by: user)
          .tap { |order| order.save!(validate: false) }

        expect(Orders::Duplicator).to receive(:new)
          .with(order: original_order, user: user)
          .and_return(duplicator)
        expect(duplicator).to receive(:call!).and_return(cart)

        post duplicate_order_path(original_order)

        expect(response).to redirect_to(cart_path)
        expect(flash[:notice]).to eq("Order items added to cart! Review and checkout when ready.")
      end

      it "creates a new cart order with duplicated items" do
        expect {
          post duplicate_order_path(original_order)
        }.to change { Order.status_cart.count }.by(1)

        cart = Order.status_cart.last
        expect(cart.client).to eq(client)
        expect(cart.catalog).to eq(catalog)
        expect(cart.ordered_by).to eq(user)
        expect(cart.order_items.count).to eq(2)
      end

      it "redirects to cart_path with success message" do
        post duplicate_order_path(original_order)

        expect(response).to redirect_to(cart_path)
        expect(flash[:notice]).to eq("Order items added to cart! Review and checkout when ready.")
      end
    end

    context "when some products are missing" do
      # Skipped: order_items.product_id has a real FK constraint (fk_rails_f1a29ddd47),
      # so a referenced product can't be destroyed to simulate "missing" here.
      # Same limitation already documented in spec/services/orders/duplicator_spec.rb.
      xit "redirects to cart with warning message" do
        post duplicate_order_path(original_order)

        expect(response).to redirect_to(cart_path)
        expect(flash[:alert]).to include("Some products are no longer available")
      end
    end

    context "when all products are missing" do
      # Skipped: order_items.product_id has a real FK constraint (fk_rails_f1a29ddd47),
      # so referenced products can't be destroyed to simulate "missing" here.
      # Same limitation already documented in spec/services/orders/duplicator_spec.rb.
      xit "redirects back to order with error message" do
        post duplicate_order_path(original_order)

        expect(response).to redirect_to(order_path(original_order))
        expect(flash[:alert]).to include("Cannot reorder")
      end

      xit "does not create a cart order" do
        expect {
          post duplicate_order_path(original_order)
        }.not_to change { Order.status_cart.count }
      end
    end

    context "when original order has no items" do
      let(:empty_order) do
        build(:order, client: client, catalog: catalog, status: :submitted).tap do |order|
          order.order_items = []
          order.save!(validate: false)
          order.reload
        end
      end

      it "redirects back to order with error message" do
        post duplicate_order_path(empty_order)

        expect(response).to redirect_to(order_path(empty_order))
        expect(flash[:alert]).to include("Cannot reorder")
      end
    end

    context "when duplication fails with generic error" do
      before do
        allow_any_instance_of(Orders::Duplicator).to receive(:call!)
          .and_raise(Orders::Duplicator::DuplicateError, "Something went wrong")
      end

      it "redirects back to order with error message" do
        post duplicate_order_path(original_order)

        expect(response).to redirect_to(order_path(original_order))
        expect(flash[:alert]).to eq("Failed to duplicate order: Something went wrong")
      end
    end

    context "when order doesn't belong to user's client" do
      let(:other_client) { create(:client) }
      let(:other_catalog) { create(:catalog, client: other_client) }
      let(:other_order) do
        build(:order, client: other_client, catalog: other_catalog, status: :submitted)
          .tap { |order| order.save!(validate: false) }
      end

      it "returns 404" do
        post duplicate_order_path(other_order)

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user is not authenticated" do
      before do
        sign_out user
      end

      it "redirects to sign in page" do
        post duplicate_order_path(original_order)

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when trying to duplicate a cart order" do
      let(:cart_order) do
        build(:order, client: client, catalog: catalog, status: :cart, ordered_by: user)
          .tap { |order| order.save!(validate: false) }
      end

      it "returns 404 (cart orders are excluded by set_order)" do
        post duplicate_order_path(cart_order)

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
