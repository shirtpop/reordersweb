require 'rails_helper'

RSpec.describe Client::InventoryMovement, type: :model do
  # See spec/models/client/inventory_spec.rb for why :without_users is needed here.
  let(:client) { create(:client, :without_users) }
  let(:variant) { create(:client_product_variant, client_product: create(:client_product, client: client)) }
  let(:inventory) { create(:client_inventory, client: client, client_product_variant: variant, quantity: 15, minimum_quantity: 10) }
  let(:user) { create(:user) }
  let(:notifier) { instance_double(Inventories::LowStockNotifier, call: nil) }

  before do
    allow(Inventories::LowStockNotifier).to receive(:new).and_return(notifier)
  end

  it "increments the inventory quantity on add" do
    create(:client_inventory_movement, client_inventory: inventory, user: user, movement_type: :add, quantity: 5)
    expect(inventory.reload.quantity).to eq(20)
  end

  it "decrements the inventory quantity on subtract" do
    create(:client_inventory_movement, client_inventory: inventory, user: user, movement_type: :subtract, quantity: 5)
    expect(inventory.reload.quantity).to eq(10)
  end

  it "notifies once quantity crosses at or below the threshold" do
    create(:client_inventory_movement, client_inventory: inventory, user: user, movement_type: :subtract, quantity: 10)

    expect(Inventories::LowStockNotifier).to have_received(:new).with(inventory)
    expect(notifier).to have_received(:call)
  end

  it "does not notify again while quantity stays below the threshold" do
    create(:client_inventory_movement, client_inventory: inventory, user: user, movement_type: :subtract, quantity: 10)
    create(:client_inventory_movement, client_inventory: inventory, user: user, movement_type: :subtract, quantity: 1)

    expect(Inventories::LowStockNotifier).to have_received(:new).once
  end

  it "does not notify when the threshold is disabled" do
    inventory.update!(minimum_quantity: 0)

    create(:client_inventory_movement, client_inventory: inventory, user: user, movement_type: :subtract, quantity: 10)

    expect(Inventories::LowStockNotifier).not_to have_received(:new)
  end

  it "does not notify on a movement that stays above the threshold" do
    create(:client_inventory_movement, client_inventory: inventory, user: user, movement_type: :subtract, quantity: 1)

    expect(Inventories::LowStockNotifier).not_to have_received(:new)
  end
end
