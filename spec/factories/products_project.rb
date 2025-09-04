FactoryBot.define do
  factory :products_project do
    association :project
    association :product
  end
end
