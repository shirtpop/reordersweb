require 'rails_helper'

RSpec.describe Clients::WizardStepValidator do
  describe "step 2 (user emails)" do
    def errors_for(users_attributes)
      described_class.new(step: 2, params: { client: { users_attributes: users_attributes } }).errors
    end

    it "requires at least one email" do
      errors = errors_for({})
      expect(errors[:email]).to include("can't be blank")
    end

    it "flags an invalid email format" do
      errors = errors_for({ "0" => { email: "not-an-email" } })
      expect(errors["email_1"]).to include("is not a valid email address")
    end

    it "flags an email already taken" do
      create(:user, email: "taken@example.com")

      errors = errors_for({ "0" => { email: "taken@example.com" } })
      expect(errors["email_1"]).to include("has already been taken")
    end

    it "flags duplicate emails within the same submission" do
      errors = errors_for({
        "0" => { email: "dup@example.com" },
        "1" => { email: "dup@example.com" }
      })

      expect(errors["email_1"]).to include("is listed more than once")
      expect(errors["email_2"]).to include("is listed more than once")
    end

    it "is valid for distinct, well-formed, unused emails" do
      errors = errors_for({
        "0" => { email: "one@example.com" },
        "1" => { email: "two@example.com" }
      })

      expect(errors).to be_empty
    end
  end
end
