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

    it "requires purpose" do
      checkout.purpose = nil
      expect(checkout).not_to be_valid
      expect(checkout.errors[:purpose]).to be_present
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

  describe "date scopes" do
    let!(:old_checkout) { create(:client_checkout, :confirmed, created_at: 10.days.ago) }
    let!(:recent_checkout) { create(:client_checkout, :confirmed, created_at: 1.day.ago) }

    describe ".created_from" do
      it "includes checkouts on or after the given date" do
        expect(Client::Checkout.created_from(3.days.ago)).to contain_exactly(recent_checkout)
      end
    end

    describe ".created_to" do
      it "includes checkouts on or before the given date" do
        expect(Client::Checkout.created_to(3.days.ago)).to contain_exactly(old_checkout)
      end
    end
  end
end
