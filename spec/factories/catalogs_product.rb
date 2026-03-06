FactoryBot.define do
  factory :catalogs_product do
    association :catalog
    association :product
  end
end
