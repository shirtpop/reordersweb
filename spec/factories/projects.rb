FactoryBot.define do
  factory :project do
    client
    name { Faker::App.name }
    description { Faker::Lorem.sentence }
    status { "active" }

    trait :with_products do
      after(:create) do |project, evaluator|
        products = create_list(:product, 3)
        products.each do |product|
          create(:products_project, project: project, product: product)
        end
      end
    end
  end
end
