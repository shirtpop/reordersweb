require 'rails_helper'

RSpec.describe Client::Product, type: :model do
  describe "product_id uniqueness scoped to client" do
    let(:client) { create(:client) }
    let(:product) { create(:product) }

    it "is invalid when the same client already has a Client::Product for that product_id" do
      create(:client_product, client: client, admin_product: product)
      duplicate = build(:client_product, client: client, admin_product: product)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:product_id]).to be_present
    end

    it "is valid when two Client::Products for the same client both have a nil product_id" do
      create(:client_product, client: client, admin_product: nil)
      other = build(:client_product, client: client, admin_product: nil)

      expect(other).to be_valid
    end

    it "is valid when two different clients each have a Client::Product for the same product_id" do
      other_client = create(:client)
      create(:client_product, client: client, admin_product: product)
      other = build(:client_product, client: other_client, admin_product: product)

      expect(other).to be_valid
    end
  end

  describe "creating with nested product_variants_attributes" do
    # create(:client)'s default `users { [ association(:user) ] }` currently fails against
    # User's admin_cannot_belong_to_client validation (pre-existing, unrelated to this spec) —
    # :without_users sidesteps it so these examples exercise real persisted records.
    let(:client) { create(:client, :without_users) }

    it "sets client_id on the built variants from the (unsaved) parent, not the database" do
      # Regression test: Client::ProductVariant#client is required, and is normally
      # backfilled from client_product.client_id in a before_validation callback. That
      # only works if `variant.client_product` is the very same in-memory object being
      # built here — which needs inverse_of on both sides, since Rails can't auto-detect
      # it when both associations use a non-default class_name (Client::Product /
      # Client::ProductVariant). Without inverse_of, variant.client_product reads back
      # nil (the parent has no id yet to look it up by), so client_id never gets set and
      # save fails with "Client must exist".
      product = client.client_products.new(
        name: "Regression Test Tee",
        product_variants_attributes: { "0" => { color: "Red", size: "M" } }
      )

      expect(product.save).to be(true)
      expect(product.product_variants.first.client_id).to eq(client.id)
    end
  end

  describe "#reorder_catalog" do
    # create(:client)'s default `users { [ association(:user) ] }` currently fails against
    # User's admin_cannot_belong_to_client validation (pre-existing, unrelated to this spec) —
    # :without_users sidesteps it so these examples exercise real persisted records.
    let(:client) { create(:client, :without_users) }
    let(:admin_product) { create(:product) }

    it "is nil when there is no admin_product link" do
      client_product = create(:client_product, client: client, admin_product: nil)

      expect(client_product.reorder_catalog).to be_nil
    end

    it "is nil when the admin product isn't assigned to any active catalog this client can browse" do
      client_product = create(:client_product, client: client, admin_product: admin_product)

      expect(client_product.reorder_catalog).to be_nil
    end

    it "finds an active catalog belonging to this client that carries the admin product" do
      client_product = create(:client_product, client: client, admin_product: admin_product)
      catalog = create(:catalog, client: client, status: :active)
      create(:catalogs_product, catalog: catalog, product: admin_product)

      expect(client_product.reorder_catalog).to eq(catalog)
    end

    it "ignores catalogs that are not active" do
      client_product = create(:client_product, client: client, admin_product: admin_product)
      draft_catalog = create(:catalog, client: client, status: :draft)
      create(:catalogs_product, catalog: draft_catalog, product: admin_product)

      expect(client_product.reorder_catalog).to be_nil
    end

    it "finds an active catalog belonging to one of this client's children" do
      child = create(:client, :without_users, parent: client)
      client_product = create(:client_product, client: client, admin_product: admin_product)
      child_catalog = create(:catalog, client: child, status: :active)
      create(:catalogs_product, catalog: child_catalog, product: admin_product)

      expect(client_product.reorder_catalog).to eq(child_catalog)
    end
  end
end
