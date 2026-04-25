FactoryBot.define do
  factory :product do
    name { Faker::Commerce.product_name }
    description { Faker::Lorem.sentence }

    price_info do
      {
        base_price: Faker::Commerce.price(range: 10.0..20.0),
        minimum_order: 6,
        bulk_prices: nil
      }
    end

    sizes { Product::SIZES.sample(5) }

    after(:build) do |product|
      if product.product_colors.empty?
        product.product_colors.build(
          name: Faker::Color.color_name,
          hex_color: Faker::Color.hex_color,
          minimum_order: product.minimum_order.to_i
        )
      end
    end

    trait :with_colors do
      price_info do
        {
          base_price: Faker::Commerce.price(range: 10.0..20.0),
          minimum_order: 12,
          bulk_prices: nil
        }
      end

      after(:build) do |product|
        product.product_colors.clear
        3.times do
          product.product_colors.build(
            name: Faker::Color.color_name,
            hex_color: Faker::Color.hex_color,
            minimum_order: 4
          )
        end
      end
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
