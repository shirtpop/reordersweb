# frozen_string_literal: true

require "rails_helper"

RSpec.describe Checkouts::Creator, type: :service do
  let(:client) { create(:client) }
  let(:user) { create(:user, :client, client: client) }
  let(:client_product) { create(:client_product, :with_variants, :without_admin_product, client: client) }
  let(:variant) { client_product.product_variants.first }
  let(:inventory) { create(:client_inventory, client: client, client_product_variant: variant, quantity: 50) }
  let(:checkout) { create(:client_checkout, :draft, client: client, user: user) }
  let!(:checkout_item) { create(:client_checkout_item, client_checkout: checkout, client_inventory: inventory, quantity: 5) }

  subject(:creator) { described_class.new(user: user, checkout: checkout) }

  describe "#initialize" do
    it "sets user and checkout attributes" do
      aggregate_failures do
        expect(creator.user).to eq(user)
        expect(creator.checkout).to eq(checkout)
      end
    end
  end

  describe "#call!" do
    context "when checkout creation is successful" do
      before do
        checkout.update_columns(
          recipient_email: "test@example.com",
          recipient_first_name: "Test",
          recipient_last_name: "User"
        )
      end

      it "marks checkout as confirmed" do
        creator.call!
        expect(checkout.reload.status).to eq("confirmed")
      end

      it "creates inventory_movements for each checkout_item" do
        expect { creator.call! }.to change(Client::InventoryMovement, :count).by(1)

        movement = checkout.reload.inventory_movements.first
        aggregate_failures do
          expect(movement.client_inventory).to eq(inventory)
          expect(movement.movement_type).to eq("stock_out")
          expect(movement.quantity).to eq(-5)
          expect(movement.user).to eq(user)
        end
      end

      it "decrements inventory quantities" do
        expect { creator.call! }.to change { inventory.reload.quantity }.from(50).to(45)
      end

      it "uses database locks to prevent race conditions" do
        expect_any_instance_of(Client::Inventory).to receive(:with_lock).and_call_original
        creator.call!
      end
    end

    context "when checkout has no items" do
      before { checkout_item.destroy! }

      it "raises CheckoutCreationError" do
        expect { creator.call! }.to raise_error(Checkouts::Creator::CheckoutCreationError, /No items/)
      end

      it "does not mark checkout as confirmed" do
        expect { creator.call! rescue nil }.not_to change { checkout.reload.status }
      end
    end

    context "when inventory has insufficient stock" do
      let!(:checkout_item) { create(:client_checkout_item, client_checkout: checkout, client_inventory: inventory, quantity: 60) }

      it "raises StockUpdateError" do
        expect { creator.call! }.to raise_error(Checkouts::Creator::StockUpdateError, /Insufficient stock/)
      end

      it "does not mark checkout as confirmed" do
        expect { creator.call! rescue nil }.not_to change { checkout.reload.status }
      end

      it "does not update inventory quantities" do
        expect { creator.call! rescue nil }.not_to change { inventory.reload.quantity }
      end
    end

    context "with multiple checkout items" do
      let(:variant2) { client_product.product_variants.second }
      let(:inventory2) { create(:client_inventory, client: client, client_product_variant: variant2, quantity: 30) }
      let!(:checkout_item2) { create(:client_checkout_item, client_checkout: checkout, client_inventory: inventory2, quantity: 10) }

      before do
        checkout.update_columns(
          recipient_email: "test@example.com",
          recipient_first_name: "Test",
          recipient_last_name: "User"
        )
      end

      it "processes all items and decrements stock" do
        creator.call!
        expect(inventory.reload.quantity).to eq(45)
        expect(inventory2.reload.quantity).to eq(20)
      end

      it "rolls back all changes if any item fails" do
        checkout_item2.update_column(:quantity, 40)

        expect { creator.call! }.to raise_error(Checkouts::Creator::StockUpdateError)

        expect(inventory.reload.quantity).to eq(50)
        expect(inventory2.reload.quantity).to eq(30)
      end
    end

    context "transaction behavior" do
      it "wraps the entire operation in a transaction" do
        allow_any_instance_of(Client::Inventory).to receive(:with_lock).and_raise(StandardError, "DB error")

        expect { creator.call! }.to raise_error(StandardError, "DB error")
        expect(inventory.reload.quantity).to eq(50)
      end
    end
  end

  describe "#success?" do
    context "when checkout is successfully confirmed" do
      before do
        checkout.update_columns(
          recipient_email: "test@example.com",
          recipient_first_name: "Test",
          recipient_last_name: "User"
        )
      end

      it "returns true after successful call" do
        creator.call!
        expect(creator.success?).to be true
      end
    end

    it "returns false before call" do
      expect(creator.success?).to be false
    end
  end

  describe "error classes" do
    it { expect(Checkouts::Creator::Error).to be < StandardError }
    it { expect(Checkouts::Creator::CheckoutCreationError).to be < Checkouts::Creator::Error }
    it { expect(Checkouts::Creator::StockUpdateError).to be < Checkouts::Creator::Error }
  end
end
