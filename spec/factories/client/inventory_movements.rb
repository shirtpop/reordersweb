FactoryBot.define do
  factory :client_inventory_movement, class: 'Client::InventoryMovement' do
    movement_type { :stock_in }
    quantity { 10 }
    metadata { {} }

    association :client
    association :client_inventory
  end
end
