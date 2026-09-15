require 'rails_helper'

RSpec.describe Inventories::LowStockNotifier, type: :service do
  # See spec/models/client/inventory_spec.rb for why :without_users is needed here.
  let(:client) { create(:client, :without_users) }

  def build_client_inventory(admin_linked:)
    admin_product = admin_linked ? create(:product) : nil
    client_product = create(:client_product, client: client, admin_product: admin_product)
    variant = create(:client_product_variant, client_product: client_product)
    create(:client_inventory, client: client, client_product_variant: variant, quantity: 5, minimum_quantity: 10)
  end

  describe "#call" do
    it "enqueues a low stock email when the product is admin-linked and the client has active users" do
      create(:user, :client, client: client, active: true)
      client_inventory = build_client_inventory(admin_linked: true)

      expect { described_class.new(client_inventory).call }
        .to have_enqueued_mail(LowStockMailer, :low_stock_alert).with(params: { client_inventory_id: client_inventory.id }, args: [])
    end

    it "does not send an email when the product has no admin_product link" do
      create(:user, :client, client: client, active: true)
      client_inventory = build_client_inventory(admin_linked: false)

      expect { described_class.new(client_inventory).call }.not_to have_enqueued_mail(LowStockMailer)
    end

    it "does not send an email when the client has no active client users" do
      client_inventory = build_client_inventory(admin_linked: true)

      expect { described_class.new(client_inventory).call }.not_to have_enqueued_mail(LowStockMailer)
    end

    it "creates a low_stock notification for each active client user" do
      user = create(:user, :client, client: client, active: true)
      client_inventory = build_client_inventory(admin_linked: true)

      expect { described_class.new(client_inventory).call }
        .to change { user.notifications.count }.by(1)

      notification = user.notifications.last
      aggregate_failures do
        expect(notification.notifiable).to eq(client_inventory)
        expect(notification.kind_low_stock?).to be true
      end
    end

    it "creates a notification even when the product has no admin_product link (only the email is gated by that)" do
      user = create(:user, :client, client: client, active: true)
      client_inventory = build_client_inventory(admin_linked: false)

      expect { described_class.new(client_inventory).call }
        .to change { user.notifications.count }.by(1)
    end

    it "creates an out_of_stock notification when the inventory has zero quantity" do
      user = create(:user, :client, client: client, active: true)
      client_inventory = build_client_inventory(admin_linked: true)
      client_inventory.update!(quantity: 0)

      described_class.new(client_inventory).call

      expect(user.notifications.last.kind_out_of_stock?).to be true
    end

    it "does not create notifications when the client has no active client users" do
      client_inventory = build_client_inventory(admin_linked: true)

      expect { described_class.new(client_inventory).call }.not_to change(Notification, :count)
    end
  end
end
