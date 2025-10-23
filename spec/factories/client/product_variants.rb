FactoryBot.define do
  factory :client_product_variant, class: 'Client::ProductVariant' do
    client_product
    color { Faker::Color.color_name }
    size { Product::SIZES.sample }
    sku { Faker::Alphanumeric.alphanumeric(number: 10) }
  end
end
