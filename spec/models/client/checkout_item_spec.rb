require "rails_helper"

RSpec.describe Client::CheckoutItem, type: :model do
  subject(:item) { build(:client_checkout_item) }

  describe "associations" do
    it { is_expected.to belong_to(:client_checkout).class_name("Client::Checkout") }
    it { is_expected.to belong_to(:client_inventory).class_name("Client::Inventory") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).is_greater_than(0).only_integer }
  end
end
