FactoryBot.define do
  factory :client_inventory_movement, class: 'Client::InventoryMovement' do
    movement_type { :purchase }
    quantity { 10 }
    metadata { { employee_email: "test@example.com", employee_name: "Test Employee" } }

    association :client
    association :client_inventory

    trait :sale do
      movement_type { :sale }
      quantity { 2 }
    end

    trait :return do
      movement_type { :return }
      quantity { 1 }
    end

    trait :damaged do
      movement_type { :damaged }
      quantity { 1 }
    end

    trait :adjustment do
      movement_type { :adjustment }
      quantity { 5 }
    end

    trait :restock do
      movement_type { :restock }
      quantity { 20 }
    end
  end
end
