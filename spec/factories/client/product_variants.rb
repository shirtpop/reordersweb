FactoryBot.define do
  factory :client_product_variant, class: 'Client::ProductVariant' do
    color { "MyString" }
    size { "MyString" }
    sku { "MyString" }
  end
end
