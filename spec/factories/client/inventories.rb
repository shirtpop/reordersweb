FactoryBot.define do
  factory :client_inventory, class: 'Client::Inventory' do
    client
    client_product_variant
    quantity { 0 }
  end
end
