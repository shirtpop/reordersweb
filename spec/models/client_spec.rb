require 'rails_helper'

RSpec.describe Client, type: :model do
  describe "#browsable_catalogs" do
    let(:client) { create(:client, :without_users) }

    it "includes the client's own active catalogs" do
      catalog = create(:catalog, client: client, status: :active)

      expect(client.browsable_catalogs).to contain_exactly(catalog)
    end

    it "excludes draft catalogs" do
      create(:catalog, client: client, status: :draft)

      expect(client.browsable_catalogs).to be_empty
    end

    it "includes a linked child's active catalogs" do
      child = create(:client, :without_users, parent: client)
      child_catalog = create(:catalog, client: child, status: :active)

      expect(client.browsable_catalogs).to contain_exactly(child_catalog)
    end

    it "does not include a parent's catalogs when called on the child" do
      parent = create(:client, :without_users)
      child = create(:client, :without_users, parent: parent)
      create(:catalog, client: parent, status: :active)

      expect(child.browsable_catalogs).to be_empty
    end
  end

  describe "#catalogs_for_product" do
    # create(:client)'s default `users { [ association(:user) ] }` currently fails against
    # User's admin_cannot_belong_to_client validation (pre-existing, unrelated to this spec) —
    # :without_users sidesteps it so these examples exercise real persisted records.
    let(:client) { create(:client, :without_users) }
    let(:product) { create(:product) }

    it "is empty when the product isn't assigned to any active catalog" do
      expect(client.catalogs_for_product(product.id)).to be_empty
    end

    it "is empty when the product id is blank" do
      expect(client.catalogs_for_product(nil)).to be_empty
    end

    it "includes every active catalog (own or a child's) carrying the product" do
      own_catalog = create(:catalog, client: client, status: :active)
      create(:catalogs_product, catalog: own_catalog, product: product)

      child = create(:client, :without_users, parent: client)
      child_catalog = create(:catalog, client: child, status: :active)
      create(:catalogs_product, catalog: child_catalog, product: product)

      draft_catalog = create(:catalog, client: client, status: :draft)
      create(:catalogs_product, catalog: draft_catalog, product: product)

      expect(client.catalogs_for_product(product.id)).to contain_exactly(own_catalog, child_catalog)
    end
  end
end
