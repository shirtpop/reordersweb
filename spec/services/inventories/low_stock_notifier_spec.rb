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
  end
end
