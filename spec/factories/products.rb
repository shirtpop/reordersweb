FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }
    description { Faker::Lorem.sentence }

    price_info do
      {
        base_price: Faker::Commerce.price(range: 10.0..20.0),
        minimum_order: Faker::Number.between(from: 1, to: 10),
        bulk_prices: nil
      }
    end

    sizes { Product::SIZES.sample(5) }

    colors do
      [
        {
          name: Faker::Color.color_name,
          hex: Faker::Color.hex_color
        }
      ]
    end

    trait :with_bulk_prices do
      price_info do
        {
          base_price: 20.0,
          minimum_order: 1,
          bulk_prices: [
            { "qty" => 5, "price" => 18.0 },
            { "qty" => 10, "price" => 15.0 }
          ]
        }
      end
    end
  end
end
