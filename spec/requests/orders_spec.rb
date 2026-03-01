require 'rails_helper'

RSpec.describe "Orders", type: :request do
  let(:client) { create(:client) }
  let(:project) { create(:project, client: client) }
  let(:user) { create(:user, client: client, role: :client) }

  before do
    sign_in user
  end

  describe "POST /orders/:id/duplicate" do
    let(:product1) { create(:product, base_price: 100) }
    let(:product2) { create(:product, base_price: 50) }

    let(:original_order) do
      create(:order, client: client, project: project, status: :submitted).tap do |order|
        order.order_items.destroy_all
        create(:order_item, order: order, product: product1, color: "Red", size: "M", quantity: 5)
        create(:order_item, order: order, product: product2, color: "Blue", size: "L", quantity: 3)
      end
    end

    context "when user is authenticated and order belongs to their client" do
      it "calls Orders::Duplicator with correct params" do
        duplicator = instance_double(Orders::Duplicator)
        cart = create(:order, client: client, project: project, status: :cart, ordered_by: user)

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
        }.to change { Order.in_cart.count }.by(1)

        cart = Order.in_cart.last
        expect(cart.client).to eq(client)
        expect(cart.project).to eq(project)
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
      before do
        product2.destroy
      end

      it "redirects to cart with warning message" do
        # The service will raise ProductNotFoundError, but we need to handle
        # the case where it still creates a cart with available products
        # However, based on our implementation, it raises an error immediately
        post duplicate_order_path(original_order)

        expect(response).to redirect_to(cart_path)
        expect(flash[:alert]).to include("Some products are no longer available")
      end
    end

    context "when all products are missing" do
      before do
        product1.destroy
        product2.destroy
      end

      it "redirects back to order with error message" do
        post duplicate_order_path(original_order)

        expect(response).to redirect_to(order_path(original_order))
        expect(flash[:alert]).to include("Cannot reorder")
      end

      it "does not create a cart order" do
        expect {
          post duplicate_order_path(original_order)
        }.not_to change { Order.in_cart.count }
      end
    end

    context "when original order has no items" do
      let(:empty_order) do
        create(:order, client: client, project: project, status: :submitted).tap do |order|
          order.order_items.destroy_all
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
      let(:other_project) { create(:project, client: other_client) }
      let(:other_order) do
        create(:order, client: other_client, project: other_project, status: :submitted)
      end

      it "raises ActiveRecord::RecordNotFound" do
        expect {
          post duplicate_order_path(other_order)
        }.to raise_error(ActiveRecord::RecordNotFound)
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
        create(:order, client: client, project: project, status: :cart, ordered_by: user)
      end

      it "raises ActiveRecord::RecordNotFound (cart orders are excluded by set_order)" do
        expect {
          post duplicate_order_path(cart_order)
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
