require 'rails_helper'

RSpec.describe "Notifications", type: :request do
  let(:client) { create(:client, :without_users) }
  let(:user) { create(:user, client: client, role: :client, active: true, first_time_login: false) }

  before { sign_in user }

  describe "GET /notifications" do
    it "lists the user's notifications" do
      notification = create(:notification, recipient: user, notifiable: create(:order, :with_catalog_line_items, client: client))

      get notifications_path

      expect(response.body).to include(notification.title)
    end

    it "does not show another user's notifications" do
      other_user = create(:user, :client, client: create(:client, :without_users))
      create(:notification, recipient: other_user, notifiable: create(:order, :with_catalog_line_items, client: other_user.client), title: "Someone else's notice")

      get notifications_path

      expect(response.body).not_to include("Someone else's notice")
    end
  end

  describe "POST /notifications/mark_all_read" do
    it "marks all of the current user's unread notifications as read" do
      notification = create(:notification, recipient: user, notifiable: create(:order, :with_catalog_line_items, client: client))

      post mark_all_read_notifications_path

      expect(notification.reload.read?).to be true
    end
  end
end
