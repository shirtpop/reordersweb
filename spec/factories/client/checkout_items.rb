FactoryBot.define do
  factory :client_checkout_item, class: "Client::CheckoutItem" do
    association :client_checkout, factory: [:client_checkout, :draft]
    association :client_inventory
    quantity { 1 }
  end
end
