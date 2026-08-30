require "rails_helper"

RSpec.describe LowStockMailer, type: :mailer do
  # See spec/models/client/inventory_spec.rb for why :without_users is needed here.
  let(:client) { create(:client, :without_users) }
  let(:client_product) { create(:client_product, client: client, admin_product: create(:product)) }
  let(:variant) { create(:client_product_variant, client_product: client_product) }
  let(:client_inventory) { create(:client_inventory, client: client, client_product_variant: variant, quantity: 5, minimum_quantity: 10) }

  describe "#low_stock_alert" do
    before { create(:user, :client, client: client, active: true, email: "recipient@example.com") }

    let(:mail) { described_class.with(client_inventory_id: client_inventory.id).low_stock_alert }

    it "is addressed to the client's active client-role users" do
      expect(mail.to).to eq([ "recipient@example.com" ])
    end

    it "includes the product name in the subject" do
      expect(mail.subject).to eq("Low stock alert: #{client_product.name}")
    end

    it "renders the current quantity and threshold in the body" do
      expect(mail.body.encoded).to include(client_product.name)
      expect(mail.body.encoded).to include(client_inventory.quantity.to_s)
      expect(mail.body.encoded).to include(client_inventory.minimum_quantity.to_s)
    end
  end

  context "when the client has no active client users" do
    let(:mail) { described_class.with(client_inventory_id: client_inventory.id).low_stock_alert }

    it "does not attempt to send" do
      expect(mail.to).to be_nil
    end
  end
end
