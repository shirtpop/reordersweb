FactoryBot.define do
  factory :client_checkout, class: "Client::Checkout" do
    association :client
    association :user, factory: :user

    trait :draft do
      status { "draft" }
    end

    trait :confirmed do
      status { "confirmed" }
      purpose { "Restock" }
      recipient_first_name { Faker::Name.first_name }
      recipient_last_name { Faker::Name.last_name }
    end
  end
end
