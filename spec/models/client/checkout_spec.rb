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

  describe ".sorted_by" do
    # create(:client)'s default `users { [ association(:user) ] }` currently fails against
    # User's admin_cannot_belong_to_client validation (pre-existing, unrelated to this spec) —
    # :without_users sidesteps it so these examples exercise real persisted records.
    let(:client) { create(:client, :without_users) }
    let(:user_a) { create(:user, email: "a@example.com") }
    let(:user_z) { create(:user, email: "z@example.com") }

    let!(:zack) do
      create(:client_checkout, :confirmed, client: client, user: user_z,
        recipient_first_name: "Zack", recipient_last_name: "Adams", purpose: "Zeta", department: "Sales")
    end
    let!(:amy) do
      create(:client_checkout, :confirmed, client: client, user: user_a,
        recipient_first_name: "Amy", recipient_last_name: "Brown", purpose: "Alpha", department: "Engineering")
    end

    def sorted(sort_by)
      Client::Checkout.where(client: client).sorted_by(sort_by).to_a
    end

    it "sorts by recipient name" do
      expect(sorted("recipient_asc")).to eq([ amy, zack ])
      expect(sorted("recipient_desc")).to eq([ zack, amy ])
    end

    it "sorts by purpose" do
      expect(sorted("purpose_asc")).to eq([ amy, zack ])
    end

    it "sorts by department" do
      expect(sorted("department_asc")).to eq([ amy, zack ])
    end

    it "sorts by created_by (user email)" do
      expect(sorted("created_by_asc")).to eq([ amy, zack ])
      expect(sorted("created_by_desc")).to eq([ zack, amy ])
    end

    it "sorts by number of checkout items" do
      variant = create(:client_product_variant, client_product: create(:client_product, client: client))
      inventory = create(:client_inventory, client: client, client_product_variant: variant)
      create(:client_checkout_item, client_checkout: zack, client_inventory: inventory, quantity: 5)

      expect(sorted("items_desc")).to eq([ zack, amy ])
      expect(sorted("items_asc")).to eq([ amy, zack ])
    end

    it "defaults to created_at descending for an unrecognized value" do
      expect(sorted(nil)).to eq([ amy, zack ])
    end
  end
end
