FactoryBot.define do
  factory :order do
    project { create(:project, :with_products) }
    client { project.client }
    delivery_date { Time.current.to_date }
    order_items { project.products.map { |product| build(:order_item, product: product) } }
  end
end
