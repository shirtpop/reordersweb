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
end
