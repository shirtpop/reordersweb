FactoryBot.define do
  factory :order do
    client
    delivery_date { Time.current.to_date }

    trait :with_catalog_line_items do
      catalog { create(:catalog, :with_products, client: association(:client)) }
      after(:build) do |order|
        order.order_items = order.catalog.products.map do |product|
          build(:order_item, order: order, product: product)
        end
      end
    end
  end
end
