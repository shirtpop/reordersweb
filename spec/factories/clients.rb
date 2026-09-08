FactoryBot.define do
  factory :client do
    transient do
      # Whether to auto-attach a default client-role user after create
      skip_default_user { false }
    end

    company_name { Faker::Company.name }
    personal_name { Faker::Name.name }
    phone_number { Faker::PhoneNumber.phone_number }
    company_url { Faker::Internet.url }
    # By default, create associated address and shipping_address
    address { association(:address) }
    shipping_address { address }

    # A client-role user requires client_id, which only exists once the
    # client itself is persisted, so it can't be built as a nested `users`
    # attribute (has_many validates new associated records before the
    # client has an id). Attach it after create instead.
    after(:create) do |client, evaluator|
      if !evaluator.skip_default_user && client.users.empty?
        create(:user, role: 'client', client: client)
      end
    end

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
      skip_default_user { true }
    end
    # Trait for a trial/demo client (browse-only, can't submit orders)
    trait :demo do
      demo { true }
    end
  end
end
