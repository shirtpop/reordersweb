require 'rails_helper'

RSpec.describe "Admin::Dashboard visitors log", type: :request do
  let(:admin) { create(:user, role: "admin") }

  before { sign_in admin }

  it "lists the 10 most recent sign-ins, newest first, skipping users who never signed in" do
    users = 11.times.map { |i| create(:user, current_sign_in_at: (i + 1).hours.ago) }
    never = create(:user, current_sign_in_at: nil)

    get admin_root_path

    expect(response).to be_successful
    body = response.body
    expect(body).to include(users.first.email)
    expect(body).not_to include(users.last.email)
    expect(body).not_to include(never.email)
    expect(body.index(users.first.email)).to be < body.index(users[5].email)
  end
end
