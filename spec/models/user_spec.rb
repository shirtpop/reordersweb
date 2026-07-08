require 'rails_helper'

RSpec.describe User, type: :model do
  describe "#active_for_authentication?" do
    it "is true for an active user" do
      user = build(:user, active: true)
      expect(user.active_for_authentication?).to be true
    end

    it "is false for an inactive user" do
      user = build(:user, active: false)
      expect(user.active_for_authentication?).to be false
    end
  end

  describe "#inactive_message" do
    it "returns :inactive when the user is not active" do
      user = build(:user, active: false)
      expect(user.inactive_message).to eq(:inactive)
    end
  end

  describe "activation defaults on creation" do
    it "defaults active to true for admin users regardless of the given value" do
      user = create(:user, role: "admin", active: false)
      expect(user).to be_active
    end

    it "leaves client users at whatever active value was given" do
      user = create(:user, :client, active: false)
      expect(user).not_to be_active
    end
  end
end
