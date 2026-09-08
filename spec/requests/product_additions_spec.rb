require 'rails_helper'

RSpec.describe "ProductAdditions", type: :request do
  let(:client) { create(:client, inventory_enabled: true) }
  let(:user) { create(:user, :client, client: client, active: true, first_time_login: false) }
  let(:catalog) { create(:catalog, client: client, status: 'active') }
  let(:product) do
    create(:product, sizes: [ "M", "L" ], product_colors: [ build(:product_color, name: "Red", minimum_order: 0) ])
  end

  before do
    create(:catalogs_product, catalog: catalog, product: product)
    sign_in user
  end

  describe "GET /inventories/product_additions/new" do
    context "without a product_id" do
      it "shows the picker of addable products" do
        get new_product_addition_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(product.name)
      end

      it "excludes products already added to the client's inventory" do
        create(:client_product, client: client, admin_product: product)

        get new_product_addition_path

        expect(response.body).not_to include(product.name)
      end
    end

    context "with a valid, assigned, not-yet-added product_id" do
      it "shows the quantity entry form for that product" do
        get new_product_addition_path(product_id: product.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Add to Inventory")
      end
    end

    context "with a product_id that is not assigned to the client" do
      let(:unassigned_product) { create(:product) }

      it "redirects to the picker with an alert" do
        get new_product_addition_path(product_id: unassigned_product.id)

        expect(response).to redirect_to(new_product_addition_path)
        expect(flash[:alert]).to eq("Product not available to add.")
      end
    end

    context "with a product_id that has already been added" do
      before { create(:client_product, client: client, admin_product: product) }

      it "redirects to the picker with an alert" do
        get new_product_addition_path(product_id: product.id)

        expect(response).to redirect_to(new_product_addition_path)
        expect(flash[:alert]).to eq("Product not available to add.")
      end
    end

    context "when inventory access is disabled for the client" do
      let(:client) { create(:client, inventory_enabled: false) }

      it "redirects to root with an alert" do
        get new_product_addition_path

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Inventory access is disabled.")
      end
    end
  end

  describe "POST /inventories/product_additions" do
    let(:variants_params) do
      {
        "0" => { color: "Red", size: "M", quantity: "3" }
      }
    end

    context "with a valid, assigned product_id and at least one valid variant" do
      it "adds the product to the client's inventory" do
        expect {
          post product_additions_path, params: { product_id: product.id, variants: variants_params }
        }.to change { client.client_products.count }.by(1)
      end

      it "redirects to products_path with a success notice" do
        post product_additions_path, params: { product_id: product.id, variants: variants_params }

        expect(response).to redirect_to(products_path)
        expect(flash[:notice]).to eq("#{product.name} was added to your inventory.")
      end
    end

    context "with a product_id that is not assigned to the client" do
      let(:unassigned_product) { create(:product) }

      it "does not call the service or create a Client::Product" do
        expect {
          post product_additions_path, params: { product_id: unassigned_product.id, variants: variants_params }
        }.not_to change { Client::Product.count }
      end

      it "redirects to the new form with an alert" do
        post product_additions_path, params: { product_id: unassigned_product.id, variants: variants_params }

        expect(response).to redirect_to(new_product_addition_path)
        expect(flash[:alert]).to eq("Product not available to add.")
      end
    end

    context "when the product has already been added" do
      before do
        allow(ClientInventories::AddCatalogProduct).to receive(:call!)
          .and_raise(ClientInventories::AddCatalogProduct::AlreadyAddedError, "Product has already been added to this client's inventory")
      end

      it "redirects back to the new form (with the product preselected) and an alert" do
        post product_additions_path, params: { product_id: product.id, variants: variants_params }

        expect(response).to redirect_to(new_product_addition_path(product_id: product.id))
        expect(flash[:alert]).to eq("Product has already been added to this client's inventory")
      end
    end

    context "when no variant has a valid quantity" do
      before do
        allow(ClientInventories::AddCatalogProduct).to receive(:call!)
          .and_raise(ClientInventories::AddCatalogProduct::NoQuantityError, "Enter a quantity for at least one size and color")
      end

      it "redirects back to the new form (with the product preselected) and an alert" do
        post product_additions_path, params: { product_id: product.id, variants: variants_params }

        expect(response).to redirect_to(new_product_addition_path(product_id: product.id))
        expect(flash[:alert]).to eq("Enter a quantity for at least one size and color")
      end
    end

    context "when inventory access is disabled for the client" do
      let(:client) { create(:client, inventory_enabled: false) }

      it "redirects to root with an alert and does not create anything" do
        expect {
          post product_additions_path, params: { product_id: product.id, variants: variants_params }
        }.not_to change { Client::Product.count }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Inventory access is disabled.")
      end
    end
  end
end
