require "rails_helper"

RSpec.describe "Inventories::Items", type: :request do
  let(:client) { create(:client, inventory_enabled: true) }
  let(:user) { create(:user, :client, client: client) }
  let(:draft_checkout) { create(:client_checkout, :draft, client: client, user: user) }
  let(:client_product) { create(:client_product, :with_variants, :without_admin_product, client: client) }
  let(:variant) { client_product.product_variants.first }
  let(:inventory) { create(:client_inventory, client: client, client_product_variant: variant, quantity: 10) }

  before { sign_in user }

  describe "POST /inventories/checkouts/:checkout_id/items" do
    it "creates a checkout item and responds with turbo stream" do
      post inventory_checkout_items_path(draft_checkout),
           params: { client_inventory_id: inventory.id, quantity: 2 },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(Client::CheckoutItem.count).to eq(1)
      expect(Client::CheckoutItem.last.quantity).to eq(2)
    end

    it "increments quantity when item already exists" do
      create(:client_checkout_item, client_checkout: draft_checkout, client_inventory: inventory, quantity: 3)

      post inventory_checkout_items_path(draft_checkout),
           params: { client_inventory_id: inventory.id, quantity: 2 },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(Client::CheckoutItem.count).to eq(1)
      expect(Client::CheckoutItem.last.quantity).to eq(5)
    end

    it "returns 404 for inventory not belonging to client" do
      other_inventory = create(:client_inventory, quantity: 5)

      post inventory_checkout_items_path(draft_checkout),
           params: { client_inventory_id: other_inventory.id, quantity: 1 },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /inventories/checkouts/:checkout_id/items/:id" do
    let!(:item) { create(:client_checkout_item, client_checkout: draft_checkout, client_inventory: inventory, quantity: 3) }

    it "updates quantity" do
      patch inventory_checkout_item_path(draft_checkout, item),
            params: { quantity: 5 },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(item.reload.quantity).to eq(5)
    end

    it "destroys item when quantity is 0" do
      patch inventory_checkout_item_path(draft_checkout, item),
            params: { quantity: 0 },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(Client::CheckoutItem.find_by(id: item.id)).to be_nil
    end
  end

  describe "DELETE /inventories/checkouts/:checkout_id/items/:id" do
    let!(:item) { create(:client_checkout_item, client_checkout: draft_checkout, client_inventory: inventory, quantity: 3) }

    it "destroys the item" do
      delete inventory_checkout_item_path(draft_checkout, item),
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(Client::CheckoutItem.find_by(id: item.id)).to be_nil
    end
  end

  describe "DELETE /inventories/checkouts/:checkout_id/items/clear" do
    before do
      create(:client_checkout_item, client_checkout: draft_checkout, client_inventory: inventory, quantity: 2)
    end

    it "destroys all items" do
      delete clear_inventory_checkout_items_path(draft_checkout),
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(draft_checkout.reload.checkout_items.count).to eq(0)
    end
  end
end
