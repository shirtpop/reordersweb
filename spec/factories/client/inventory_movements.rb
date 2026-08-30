FactoryBot.define do
  factory :client_inventory_movement, class: 'Client::InventoryMovement' do
    movement_type { :add }
    quantity { 10 }
    metadata { {} }

    association :client_inventory
  end
end
