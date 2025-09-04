FactoryBot.define do
  factory :client do
    company_name { Faker::Company.name }
    personal_name { Faker::Name.name }
    phone_number { Faker::PhoneNumber.phone_number }
    company_url { Faker::Internet.url }
    # By default, create associated address and shipping_address
    address { association(:address) }
    shipping_address { address }
    # By default, create one user associated with the client
    users { [ association(:user) ] }
    # Trait for client without address (since address is optional)
    trait :without_address do
      address { nil }
    end
    # Trait for client without shipping_address (optional)
    trait :without_shipping_address do
      shipping_address { nil }
    end
    # Trait for client with multiple users
    trait :with_multiple_users do
      users { build_list(:user, 3) }
    end
    # Trait for client with no users
    trait :without_users do
      users { [] }
    end
  end
end
