require 'rails_helper'

RSpec.describe Notifications::OrderProcessedNotifier, type: :service do
  let(:client) { create(:client, :without_users) }
  let(:order) { create(:order, :with_catalog_line_items, client: client) }

  describe '#call' do
    it 'notifies active client users' do
      user = create(:user, :client, client: client, active: true)

      expect { described_class.new(order).call }
        .to change { user.notifications.count }.by(1)

      notification = user.notifications.last
      aggregate_failures do
        expect(notification.notifiable).to eq(order)
        expect(notification.kind_order_processed?).to be true
        expect(notification.title).to include(order.order_number)
      end
    end

    it 'does not notify inactive client users' do
      create(:user, :client, client: client, active: false)

      expect { described_class.new(order).call }.not_to change(Notification, :count)
    end
  end
end
