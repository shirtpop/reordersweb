FactoryBot.define do
  factory :catalog do
    client
    name { Faker::App.name }
    description { Faker::Lorem.sentence }
    status { "active" }

    trait :with_products do
      after(:create) do |catalog, _|
        create(:catalogs_product, catalog: catalog, product: create(:product))
      end
    end
  end
end
