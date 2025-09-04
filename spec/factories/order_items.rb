FactoryBot.define do
  factory :order_item do
    order
    product
    quantity { 1 }
    color { "Red" }
    size { "M" }
  end
end
