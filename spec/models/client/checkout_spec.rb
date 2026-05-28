require 'rails_helper'

RSpec.describe Client::Checkout, type: :model do
  describe "status enum" do
    it "defaults to confirmed" do
      checkout = Client::Checkout.new
      expect(checkout.status).to eq("confirmed")
    end

    it "can be set to draft" do
      checkout = Client::Checkout.new(status: :draft)
      expect(checkout).to be_draft
    end
  end

  describe "validations with draft status" do
    subject(:checkout) { Client::Checkout.new(status: :draft, client: create(:client), user: create(:user, :client)) }

    it "is valid without recipient info" do
      expect(checkout).to be_valid
    end
  end

  describe "validations with confirmed status" do
    subject(:checkout) { build(:client_checkout, :confirmed) }

    it "requires recipient_email" do
      checkout.recipient_email = nil
      expect(checkout).not_to be_valid
      expect(checkout.errors[:recipient_email]).to be_present
    end

    it "requires recipient_first_name" do
      checkout.recipient_first_name = nil
      expect(checkout).not_to be_valid
    end

    it "requires recipient_last_name" do
      checkout.recipient_last_name = nil
      expect(checkout).not_to be_valid
    end
  end
end
