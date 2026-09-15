FactoryBot.define do
  factory :notification do
    recipient factory: [ :user, :client ]
    notifiable factory: :order
    kind { 'order_processed' }
    title { Faker::Lorem.sentence }
    description { Faker::Lorem.paragraph }
    read_at { nil }
  end
end
