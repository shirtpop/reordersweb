require 'rails_helper'

RSpec.describe "Admin::Users#activate", type: :request do
  let(:admin) { create(:user, role: "admin") }
  let(:client) { create(:client, :without_users) }
  let(:inactive_user) { create(:user, :client, client: client, active: false) }

  before { sign_in admin }

  it "activates the user, sets a new password, and emails their credentials" do
    expect {
      patch activate_admin_user_path(inactive_user)
    }.to have_enqueued_mail(UserMailer, :welcome_client)

    expect(inactive_user.reload).to be_active
  end

  it "changes the user's password so the old one no longer works" do
    old_encrypted_password = inactive_user.encrypted_password

    patch activate_admin_user_path(inactive_user)

    expect(inactive_user.reload.encrypted_password).not_to eq(old_encrypted_password)
  end

  it "does not reactivate or re-email an already active user" do
    active_user = create(:user, :client, client: client, active: true)

    expect {
      patch activate_admin_user_path(active_user)
    }.not_to have_enqueued_mail(UserMailer, :welcome_client)
  end
end
