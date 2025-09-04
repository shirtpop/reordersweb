FactoryBot.define do
  factory :order do
    project { create(:project, :with_products) }
    client { project.client }
    delivery_date { Time.current.to_date }

    trait :with_order_items do
      after(:create) do |order|
        create_list(:order_item, 3, order: order)
      end
    end
  end
end
