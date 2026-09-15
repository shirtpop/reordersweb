require 'rails_helper'

RSpec.describe Notifications::LowStockNotifier, type: :service do
  let(:client) { create(:client, :without_users) }

  def build_client_inventory(admin_linked:, quantity: 5)
    admin_product = admin_linked ? create(:product) : nil
    client_product = create(:client_product, client: client, admin_product: admin_product)
    variant = create(:client_product_variant, client_product: client_product)
    create(:client_inventory, client: client, client_product_variant: variant, quantity: quantity, minimum_quantity: 10)
  end

  describe '#call' do
    it 'notifies active client users regardless of whether the product is admin-linked' do
      user = create(:user, :client, client: client, active: true)
      client_inventory = build_client_inventory(admin_linked: false)

      expect { described_class.new(client_inventory).call }
        .to change { user.notifications.count }.by(1)

      notification = user.notifications.last
      aggregate_failures do
        expect(notification.notifiable).to eq(client_inventory)
        expect(notification.kind_low_stock?).to be true
      end
    end

    it 'uses out_of_stock as the kind when the inventory has zero quantity' do
      user = create(:user, :client, client: client, active: true)
      client_inventory = build_client_inventory(admin_linked: true, quantity: 0)

      described_class.new(client_inventory).call

      expect(user.notifications.last.kind_out_of_stock?).to be true
    end

    it 'does not notify inactive client users' do
      create(:user, :client, client: client, active: false)
      client_inventory = build_client_inventory(admin_linked: true)

      expect { described_class.new(client_inventory).call }.not_to change(Notification, :count)
    end
  end
end
