require 'rails_helper'

RSpec.describe "OrderCheckouts", type: :request do
  let(:client) { create(:client) }
  let(:catalog) { create(:catalog, client: client) }
  let(:user) { create(:user, client: client, role: :client) }
  let(:product) { create(:product) }

  let!(:cart) do
    order = build(:order, client: client, catalog: catalog, status: :cart, ordered_by: user)
    order.order_items = [ build(:order_item, order: order, product: product, quantity: 10) ]
    order.save!
    order
  end

  before { sign_in user }

  describe "GET /checkout" do
    context "when the client is a trial account" do
      before { client.update!(demo: true) }

      it "still renders the checkout review page" do
        get checkout_path

        expect(response).to have_http_status(:ok)
      end
    end

    context "when the client is not a trial account" do
      it "renders the checkout page" do
        get checkout_path

        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "POST /checkout" do
    let(:checkout_params) do
      { order: { delivery_date: 1.week.from_now.to_date, notes: "", purchase_order: "" } }
    end

    context "when the client is a trial account" do
      before { client.update!(demo: true) }

      it "does not submit the order" do
        expect {
          post checkout_path, params: checkout_params
        }.not_to change { cart.reload.status }

        expect(response).to redirect_to(cart_path)
        expect(flash[:alert]).to match(/trial account/i)
      end
    end

    context "when the client is not a trial account" do
      it "submits the order" do
        post checkout_path, params: checkout_params

        expect(cart.reload.status).to eq("submitted")
        expect(response).to redirect_to(order_path(cart))
      end
    end
  end
end
