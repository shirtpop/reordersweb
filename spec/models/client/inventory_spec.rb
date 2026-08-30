require 'rails_helper'

RSpec.describe Client::Inventory, type: :model do
  # `create(:client)`'s default `users { [ association(:user) ] }` currently fails against
  # User's admin_cannot_belong_to_client validation (pre-existing, unrelated to this spec) —
  # :without_users sidesteps it so these examples exercise real persisted records.
  let(:client) { create(:client, :without_users) }
  let(:variant) { create(:client_product_variant, client_product: create(:client_product, client: client)) }

  def build_inventory(quantity:, minimum_quantity:)
    build(:client_inventory, client: client, client_product_variant: variant, quantity: quantity, minimum_quantity: minimum_quantity)
  end

  def create_inventory(quantity:, minimum_quantity:)
    create(:client_inventory, client: client, client_product_variant: create(:client_product_variant, client_product: create(:client_product, client: client)),
      quantity: quantity, minimum_quantity: minimum_quantity)
  end

  describe "#stock_status" do
    it "is :out_of_stock when quantity is zero" do
      expect(build_inventory(quantity: 0, minimum_quantity: 10).stock_status).to eq(:out_of_stock)
    end

    it "is :low_stock when quantity is at or below a positive threshold" do
      expect(build_inventory(quantity: 10, minimum_quantity: 10).stock_status).to eq(:low_stock)
    end

    it "is :in_stock when quantity is above the threshold" do
      expect(build_inventory(quantity: 11, minimum_quantity: 10).stock_status).to eq(:in_stock)
    end

    it "is :in_stock when the threshold is disabled (zero), regardless of quantity" do
      expect(build_inventory(quantity: 1, minimum_quantity: 0).stock_status).to eq(:in_stock)
    end
  end

  describe ".low_stock" do
    it "only includes inventories at or below their own positive threshold" do
      low = create_inventory(quantity: 5, minimum_quantity: 10)
      healthy = create_inventory(quantity: 20, minimum_quantity: 10)
      disabled_threshold = create_inventory(quantity: 1, minimum_quantity: 0)
      out_of_stock = create_inventory(quantity: 0, minimum_quantity: 10)

      expect(Client::Inventory.low_stock.where(client: client)).to contain_exactly(low)
      expect(Client::Inventory.low_stock).not_to include(healthy, disabled_threshold, out_of_stock)
    end
  end
end
