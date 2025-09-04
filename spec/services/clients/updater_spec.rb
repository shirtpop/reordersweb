require 'rails_helper'

RSpec.describe Clients::Updater do
  let!(:client) { create(:client) }
  let(:original_address) { client.address }
  let(:original_shipping_address) { client.shipping_address }
  let(:new_address_params) do
    {
      "street" => "789 New St",
      "city" => "Star City",
      "state" => "CA",
      "zip_code" => "54321"
    }
  end
  let(:unchanged_address_params) do
    {
      "street" => client.address.street,
      "city" => client.address.city,
      "state" => client.address.state,
      "zip_code" => client.address.zip_code
    }
  end
  let(:valid_client_params) do
    {
      company_name: "Updated Company",
      personal_name: "Jane Doe",
      phone_number: "555-6789",
      address_attributes: new_address_params,
      shipping_address_attributes: new_address_params
    }
  end

  describe "#call" do
    context "when same_as_main is true and address changed" do
      subject(:updater) { described_class.new(client: client, client_params: valid_client_params, same_as_main: true) }

      it "creates a new address and assigns it as both billing and shipping" do
        expect {
          updater.call
        }.to change(Address, :count).by(1)

        updated_client = updater.call
        expect(updated_client.company_name).to eq("Updated Company")
        expect(updated_client.address.street).to eq("789 New St")
        expect(updated_client.shipping_address).to eq(updated_client.address)
        expect(updater.failed?).to be false
      end
    end

    context "when same_as_main is true and address unchanged" do
      let(:params) do
        {
          company_name: "Updated Company",
          personal_name: "Jane Doe",
          phone_number: "555-6789",
          address_attributes: unchanged_address_params,
          shipping_address_attributes: unchanged_address_params
        }
      end

      subject(:updater) { described_class.new(client: client, client_params: params, same_as_main: true) }

      it "does not create a new address and keeps the same address for billing and shipping" do
        expect {
          updater.call
        }.not_to change(Address, :count)

        updated_client = updater.call
        expect(updated_client.address).to eq(original_address)
        expect(updated_client.shipping_address).to eq(original_address)
        expect(updater.failed?).to be false
      end
    end

    context "when same_as_main is false and addresses changed" do
      let(:params) do
        {
          company_name: "Updated Company",
          personal_name: "Jane Doe",
          phone_number: "555-6789",
          address_attributes: new_address_params,
          shipping_address_attributes: {
            "street" => "321 Other St",
            "city" => "Central City",
            "state" => "IL",
            "zip_code" => "98765"
          }
        }
      end

      subject(:updater) { described_class.new(client: client, client_params: params, same_as_main: false) }

      it "creates new addresses for billing and shipping separately" do
        expect {
          updater.call
        }.to change(Address, :count).by(2)

        updated_client = updater.call
        expect(updated_client.address.street).to eq("789 New St")
        expect(updated_client.shipping_address.street).to eq("321 Other St")
        expect(updated_client.address).not_to eq(updated_client.shipping_address)
        expect(updater.failed?).to be false
      end
    end

    context "when same_as_main is false and shipping address unchanged" do
      let(:params) do
        {
          company_name: "Updated Company",
          personal_name: "Jane Doe",
          phone_number: "555-6789",
          address_attributes: new_address_params,
          shipping_address_attributes: unchanged_address_params
        }
      end

      subject(:updater) { described_class.new(client: client, client_params: params, same_as_main: false) }

      it "creates new billing address but keeps existing shipping address" do
        expect {
          updater.call
        }.to change(Address, :count).by(1)

        updated_client = updater.call
        expect(updated_client.address.street).to eq("789 New St")
        expect(updated_client.shipping_address).to eq(original_shipping_address)
        expect(updater.failed?).to be false
      end
    end

    context "when update fails due to validation errors" do
      let(:invalid_params) do
        {
          company_name: nil, # invalid, presence required
          personal_name: "Jane Doe",
          phone_number: "555-6789",
          address_attributes: new_address_params,
          shipping_address_attributes: new_address_params
        }
      end

      subject(:updater) { described_class.new(client: client, client_params: invalid_params, same_as_main: true) }

      it "does not update client and marks failed" do
        result = updater.call
        expect(result).to eq(client)
        expect(updater.failed?).to be true
        expect(client.reload.company_name).not_to be_nil
      end
    end
  end

  describe "#address_changed?" do
    subject(:updater) { described_class.new(client: client, client_params: {}, same_as_main: true) }

    it "returns true if any address attribute differs (case and whitespace insensitive)" do
      expect(
        updater.send(:address_changed?, original_address, {
          "street" => original_address.street.upcase,
          "city" => original_address.city.upcase,
          "state" => original_address.state.upcase,
          "zip_code" => original_address.zip_code.upcase
        })
      ).to be false

      expect(
        updater.send(:address_changed?, original_address, {
          "street" => "Different St",
          "city" => "metropolis",
          "state" => "ny",
          "zip_code" => "12345"
        })
      ).to be true
    end
  end
end
