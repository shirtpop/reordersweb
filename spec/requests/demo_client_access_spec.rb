require 'rails_helper'

RSpec.describe "Demo client access restrictions", type: :request do
  let(:client) { create(:client, inventory_enabled: true) }
  let(:user) { create(:user, client: client, role: :client) }

  before { sign_in user }

  shared_examples "blocked for trial accounts" do |path_helper|
    context "when the client is a trial account" do
      before { client.update!(demo: true) }

      it "redirects to root with an explanatory alert" do
        get send(path_helper)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/trial account/i)
      end
    end

    context "when the client is not a trial account" do
      it "does not block access" do
        get send(path_helper)

        expect(response).not_to redirect_to(root_path)
      end
    end
  end

  describe "GET /inventories" do
    it_behaves_like "blocked for trial accounts", :inventories_path
  end

  describe "GET /inventories/products" do
    it_behaves_like "blocked for trial accounts", :products_path
  end

  describe "GET /inventories/checkouts" do
    it_behaves_like "blocked for trial accounts", :inventory_checkouts_path
  end

  describe "GET /inventories/product_additions/new" do
    it_behaves_like "blocked for trial accounts", :new_product_addition_path
  end

  describe "GET /inventories/product_variants" do
    it_behaves_like "blocked for trial accounts", :product_variants_path
  end

  describe "GET /inventories/:id/inventory_movements" do
    let!(:inventory) { create(:client_inventory, client: client) }

    context "when the client is a trial account" do
      before { client.update!(demo: true) }

      it "redirects to root with an explanatory alert" do
        get inventory_inventory_movements_path(inventory)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to match(/trial account/i)
      end
    end

    context "when the client is not a trial account" do
      it "does not block access" do
        get inventory_inventory_movements_path(inventory)

        expect(response).not_to redirect_to(root_path)
      end
    end
  end

  context "when the client is a trial account" do
    before { client.update!(demo: true) }

    it "still allows browsing the storefront" do
      get storefront_path

      expect(response).to have_http_status(:ok)
    end

    it "still allows viewing the cart" do
      get cart_path

      expect(response).to have_http_status(:ok)
    end
  end
end
