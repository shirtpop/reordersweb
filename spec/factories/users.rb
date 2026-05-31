FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { 'password123' }
    role { 'admin' }

    trait :client do
      role { 'client' }
      association :client
    end
  end
end
