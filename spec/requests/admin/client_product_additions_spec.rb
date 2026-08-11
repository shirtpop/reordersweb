require 'rails_helper'

RSpec.describe "Admin::ClientProductAdditions", type: :request do
  let(:admin) { create(:user, role: "admin") }
  let(:client) { create(:client) }
  let(:catalog) { create(:catalog, client: client, status: 'active') }
  let(:product) do
    create(:product, sizes: [ "M", "L" ], product_colors: [ build(:product_color, name: "Red", minimum_order: 0) ])
  end

  before do
    create(:catalogs_product, catalog: catalog, product: product)
    sign_in admin
  end

  describe "GET /admin/clients/:client_id/product_additions/new" do
    context "without a product_id" do
      it "shows the picker of addable products" do
        get new_admin_client_product_additions_path(client)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(product.name)
      end

      it "excludes products already added to the client's inventory" do
        create(:client_product, client: client, admin_product: product)

        get new_admin_client_product_additions_path(client)

        expect(response.body).not_to include(product.name)
      end
    end

    context "with a valid, assigned, not-yet-added product_id" do
      it "shows the quantity entry form for that product" do
        get new_admin_client_product_additions_path(client, product_id: product.id)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Add to Inventory")
      end
    end

    context "with a product_id that is not assigned to the client" do
      let(:unassigned_product) { create(:product) }

      it "redirects to the picker with an alert" do
        get new_admin_client_product_additions_path(client, product_id: unassigned_product.id)

        expect(response).to redirect_to(new_admin_client_product_additions_path(client))
        expect(flash[:alert]).to eq("Product not available to add.")
      end
    end

    context "when signed in as a non-admin user" do
      before { sign_in create(:user, :client) }

      it "denies access" do
        get new_admin_client_product_additions_path(client)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end
  end

  describe "POST /admin/clients/:client_id/product_additions" do
    let(:variants_params) do
      {
        "0" => { color: "Red", size: "M", quantity: "3" }
      }
    end

    context "with a valid, assigned product_id and at least one valid variant" do
      it "adds the product to the client's inventory" do
        expect {
          post admin_client_product_additions_path(client), params: { product_id: product.id, variants: variants_params }
        }.to change { client.client_products.count }.by(1)
      end

      it "redirects back to the add-product picker with a success notice, so another product can be added right away" do
        post admin_client_product_additions_path(client), params: { product_id: product.id, variants: variants_params }

        expect(response).to redirect_to(new_admin_client_product_additions_path(client))
        expect(flash[:notice]).to eq("#{product.name} was added to #{client.company_name}'s inventory.")
      end
    end

    context "with a product_id that is not assigned to the client" do
      let(:unassigned_product) { create(:product) }

      it "does not create a Client::Product" do
        expect {
          post admin_client_product_additions_path(client), params: { product_id: unassigned_product.id, variants: variants_params }
        }.not_to change { Client::Product.count }
      end

      it "redirects to the new form with an alert" do
        post admin_client_product_additions_path(client), params: { product_id: unassigned_product.id, variants: variants_params }

        expect(response).to redirect_to(new_admin_client_product_additions_path(client))
        expect(flash[:alert]).to eq("Product not available to add.")
      end
    end

    context "when the product has already been added" do
      before do
        allow(ClientInventories::AddCatalogProduct).to receive(:call!)
          .and_raise(ClientInventories::AddCatalogProduct::AlreadyAddedError, "Product has already been added to this client's inventory")
      end

      it "redirects back to the new form (with the product preselected) and an alert" do
        post admin_client_product_additions_path(client), params: { product_id: product.id, variants: variants_params }

        expect(response).to redirect_to(new_admin_client_product_additions_path(client, product_id: product.id))
        expect(flash[:alert]).to eq("Product has already been added to this client's inventory")
      end
    end

    context "when no variant has a valid quantity" do
      before do
        allow(ClientInventories::AddCatalogProduct).to receive(:call!)
          .and_raise(ClientInventories::AddCatalogProduct::NoQuantityError, "Enter a quantity for at least one size and color")
      end

      it "redirects back to the new form (with the product preselected) and an alert" do
        post admin_client_product_additions_path(client), params: { product_id: product.id, variants: variants_params }

        expect(response).to redirect_to(new_admin_client_product_additions_path(client, product_id: product.id))
        expect(flash[:alert]).to eq("Enter a quantity for at least one size and color")
      end
    end

    context "when signed in as a non-admin user" do
      before { sign_in create(:user, :client) }

      it "denies access and creates nothing" do
        expect {
          post admin_client_product_additions_path(client), params: { product_id: product.id, variants: variants_params }
        }.not_to change { Client::Product.count }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Access denied.")
      end
    end
  end
end
