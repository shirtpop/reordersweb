FactoryBot.define do
  factory :client_product, class: 'Client::Product' do
    client { nil }
    product { nil }
    name { "MyString" }
  end
end
