require 'rails_helper'

RSpec.describe Clients::Creator do
  let(:valid_address_params) do
    {
      street: "123 Main St",
      city: "Metropolis",
      state: "NY",
      zip_code: "12345"
    }
  end

  let(:valid_user_params) do
    {
      "0" => {
        email: "user@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }
  end

  let(:valid_client_params) do
    {
      company_name: "Acme Corp",
      personal_name: "John Doe",
      phone_number: "555-1234",
      address_attributes: valid_address_params,
      shipping_address_attributes: valid_address_params,
      users_attributes: valid_user_params
    }
  end

  describe "#call!" do
    context "when valid params and same_as_main is true" do
      subject(:creator) { described_class.new(client_params: valid_client_params, same_as_main: true) }

      it "creates client with one address used for both billing and shipping" do
        expect {
          creator.call!
        }.to change(Client, :count).by(1)
          .and change(Address, :count).by(1)
          .and change(User, :count).by(1)

        client = creator.client
        expect(client).to be_persisted
        expect(client.address).to eq(client.shipping_address)
        expect(creator).to be_success
      end

      it "sends welcome email to created user" do
        expect {
          creator.call!
        }.to have_enqueued_mail(UserMailer, :welcome_client).with(
          hash_including(params: hash_including(user_id: kind_of(Integer), password: "password123"))
        )
      end
    end

    context "when valid params and same_as_main is false" do
      subject(:creator) { described_class.new(client_params: valid_client_params, same_as_main: false) }

      it "creates client with separate billing and shipping addresses" do
        expect {
          creator.call!
        }.to change(Client, :count).by(1)
          .and change(Address, :count).by(2)
          .and change(User, :count).by(1)

        client = creator.client
        expect(client).to be_persisted
        expect(client.address).not_to eq(client.shipping_address)
        expect(creator).to be_success
      end
    end

    context "when invalid client params" do
      let(:invalid_params) do
        valid_client_params.merge(company_name: nil) # company_name is required
      end

      subject(:creator) { described_class.new(client_params: invalid_params, same_as_main: true) }

      it "does not create client or addresses or users" do
        expect {
          creator.call!
        }.to change(Client, :count).by(0)
          .and change(Address, :count).by(0)
          .and change(User, :count).by(0)
        expect(creator.success?).to be false
        expect(creator.client).not_to be_persisted
        expect(creator.client.errors[:company_name]).to include("can't be blank")
      end
    end

    context "when user params are missing" do
      let(:params_without_users) do
        valid_client_params.except(:users_attributes)
      end

      subject(:creator) { described_class.new(client_params: params_without_users, same_as_main: true) }

      it "creates client and addresses but no users" do
        expect {
          creator.call!
        }.to change(Client, :count).by(1)
          .and change(Address, :count).by(1)
          .and change(User, :count).by(0)

        expect(creator).to be_success
      end
    end
  end
end
