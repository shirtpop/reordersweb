FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }
    description { Faker::Lorem.sentence }

    price_info do
      {
        base_price: Faker::Commerce.price(range: 10.0..20.0),
        minimum_order: Faker::Number.between(from: 1, to: 10)
      }
    end

    sizes { %w[S M L XL] }

    colors do
      [
        {
          name: Faker::Color.color_name,
          hex: Faker::Color.hex_color
        }
      ]
    end
  end
end
