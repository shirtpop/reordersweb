FactoryBot.define do
  factory :order do
    client
    catalog { create(:catalog, :with_products, client: client) }
    delivery_date { Time.current.to_date }

    after(:build) do |order|
      order.order_items = order.catalog.products.map do |product|
        build(:order_item, order: order, product: product)
      end
    end
  end
end
