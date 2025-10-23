FactoryBot.define do
  factory :client_product, class: 'Client::Product' do
    client
    admin_product { create(:product) }
    name { Faker::Commerce.product_name }
    description { Faker::Lorem.paragraph }

    trait :with_variants do
      after(:create) do |client_product, evaluator|
        create_list(:client_product_variant, 3, client_product: client_product)
      end
    end

    trait :with_admin_product do
      admin_product { create(:product) }
    end

    trait :without_admin_product do
      admin_product { nil }
    end
  end
end
