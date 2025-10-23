FactoryBot.define do
  factory :project do
    client
    name { Faker::App.name }
    description { Faker::Lorem.sentence }
    status { "active" }

    trait :with_products do
      after(:create) do |project, _|
        create(:products_project, project: project, product: create(:product))
      end
    end
  end
end
