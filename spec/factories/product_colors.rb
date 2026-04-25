FactoryBot.define do
  factory :product_color do
    association :product
    name { Faker::Color.color_name }
    hex_color { Faker::Color.hex_color }
    minimum_order { 6 }
  end
end
