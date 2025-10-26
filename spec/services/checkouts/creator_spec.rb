# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Checkouts::Creator, type: :service do
  subject(:creator) { described_class.new(user: user, checkout: checkout) }

  let(:client) { create(:client) }
  let(:user) { client.users.first }
  let(:client_product) { create(:client_product, :with_variants, :without_admin_product, client: client) }
  let(:client_product_variant) { client_product.product_variants.first }
  let(:inventory) { create(:client_inventory, client: client, client_product_variant: client_product_variant, quantity: 50) }
  let(:checkout_params) do
    {
      recipient_email: 'test@example.com',
      recipient_first_name: 'Test',
      recipient_last_name: 'User',
      inventory_movements_attributes: [
        { client_inventory_id: inventory.id, quantity: 5 }
      ]
    }
  end
  let(:checkout) { client.checkouts.new(checkout_params) }

  describe '#initialize' do
    it 'sets user and checkout attributes' do
      aggregate_failures do
        expect(creator.user).to eq(user)
        expect(creator.checkout).to eq(checkout)
      end
    end
  end

  describe '#call!' do
    context 'when checkout creation is successful' do
      it 'creates the checkout and updates inventory quantities' do
        expect { creator.call! }.to change(Client::Checkout, :count).by(1)

        created_checkout = creator.checkout
        aggregate_failures do
          expect(created_checkout).to be_persisted
          expect(created_checkout.user).to eq(user)
          expect(created_checkout.client).to eq(client)
        end
      end

      it 'sets user and movement_type to stock_out for all inventory movements' do
        creator.call!

        created_checkout = creator.checkout
        movement = created_checkout.inventory_movements.first

        aggregate_failures do
          expect(movement.user).to eq(user)
          expect(movement.movement_type).to eq('stock_out')
        end
      end

      it 'decrements inventory quantities' do
        expect { creator.call! }.to change { inventory.reload.quantity }.from(50).to(45)
      end

      it 'uses database locks to prevent race conditions' do
        expect_any_instance_of(Client::Inventory).to receive(:with_lock).and_call_original
        creator.call!
      end
    end

    context 'when inventory has insufficient stock' do
      let(:checkout_params) do
        {
          recipient_email: 'test@example.com',
          recipient_first_name: 'Test',
          recipient_last_name: 'User',
          inventory_movements_attributes: [
            { client_inventory_id: inventory.id, quantity: 60 }
          ]
        }
      end

      it 'raises StockUpdateError' do
        expect { creator.call! }.to raise_error(Checkouts::Creator::StockUpdateError, "Insufficient stock for #{inventory.id}")
      end

      it 'does not create the checkout' do
        expect { creator.call! rescue nil }.not_to change(Client::Checkout, :count)
      end

      it 'does not update inventory quantities' do
        expect { creator.call! rescue nil }.not_to change { inventory.reload.quantity }
      end
    end

    context 'when inventory is missing for movement' do
      let(:checkout_params) do
        {
          recipient_email: 'test@example.com',
          recipient_first_name: 'Test',
          recipient_last_name: 'User',
          inventory_movements_attributes: [
            { client_inventory_id: nil, quantity: 5 }
          ]
        }
      end

      it 'raises StockUpdateError' do
        expect { creator.call! }.to raise_error(Checkouts::Creator::StockUpdateError, /Missing inventory for movement/)
      end
    end

    context 'when checkout validation fails' do
      let(:checkout_params) do
        {
          recipient_email: nil, # Invalid email
          recipient_first_name: 'Test',
          recipient_last_name: 'User',
          inventory_movements_attributes: [
            { client_inventory_id: inventory.id, quantity: 5 }
          ]
        }
      end

      it 'raises CheckoutCreationError' do
        expect { creator.call! }.to raise_error(Checkouts::Creator::CheckoutCreationError, /Failed to create checkout/)
      end

      it 'does not create the checkout' do
        expect { creator.call! rescue nil }.not_to change(Client::Checkout, :count)
      end
    end

    context 'with multiple inventory movements' do
      let(:inventory2) { create(:client_inventory, client: client, client_product_variant: client_product.product_variants.second, quantity: 30) }
      let(:checkout_params) do
        {
          recipient_email: 'test@example.com',
          recipient_first_name: 'Test',
          recipient_last_name: 'User',
          inventory_movements_attributes: [
            { client_inventory_id: inventory.id, quantity: 5 },
            { client_inventory_id: inventory2.id, quantity: 10 }
          ]
        }
      end

      it 'processes all movements successfully' do
        expect { creator.call! }.to change(Client::Checkout, :count).by(1)

        expect(inventory.reload.quantity).to eq(45)
        expect(inventory2.reload.quantity).to eq(20)
      end

      it 'rolls back all changes if any movement fails' do
        # Create a new checkout with insufficient stock for one movement
        checkout_params[:inventory_movements_attributes][1][:quantity] = 40 # More than available stock

        expect { creator.call! }.to raise_error(Checkouts::Creator::StockUpdateError)

        expect(inventory.reload.quantity).to eq(50)
        expect(inventory2.reload.quantity).to eq(30)
      end
    end

    context 'transaction behavior' do
      it 'wraps the entire operation in a database transaction' do
        # Test that the operation is transactional by ensuring rollback works
        allow_any_instance_of(Client::Inventory).to receive(:with_lock).and_raise(StandardError.new("Database error"))

        expect { creator.call! }.to raise_error(StandardError, "Database error")
        expect(inventory.reload.quantity).to eq(50)
      end
    end
  end

  describe '#success?' do
    context 'when checkout is successfully created' do
      it 'returns true' do
        creator.call!

        expect(creator.success?).to be true
      end
    end

    context 'when checkout has validation errors' do
      let(:checkout_params) do
        {
          recipient_email: nil, # Invalid email
          recipient_first_name: 'Test',
          recipient_last_name: 'User',
          inventory_movements_attributes: [
            { client_inventory_id: inventory.id, quantity: 5 }
          ]
        }
      end

      it 'returns false' do
        expect { creator.call! }.to raise_error(Checkouts::Creator::CheckoutCreationError)
        expect(creator.success?).to be false
      end
    end

    context 'when checkout is not persisted' do
      it 'returns false' do
        expect(creator.success?).to be false
      end
    end
  end

  describe '#validate_stock!' do
    context 'when all movements have sufficient stock' do
      it 'does not raise any error' do
        expect { creator.send(:validate_stock!) }.not_to raise_error
      end
    end

    context 'when a movement has insufficient stock' do
      let(:checkout_params) do
        {
          recipient_email: 'test@example.com',
          recipient_first_name: 'Test',
          recipient_last_name: 'User',
          inventory_movements_attributes: [
            { client_inventory_id: inventory.id, quantity: 60 }
          ]
        }
      end

      it 'raises StockUpdateError' do
        expect { creator.send(:validate_stock!) }.to raise_error(Checkouts::Creator::StockUpdateError, "Insufficient stock for #{inventory.id}")
      end
    end

    context 'when a movement has missing inventory' do
      let(:checkout_params) do
        {
          recipient_email: 'test@example.com',
          recipient_first_name: 'Test',
          recipient_last_name: 'User',
          inventory_movements_attributes: [
            { client_inventory_id: nil, quantity: 5 }
          ]
        }
      end

      it 'raises StockUpdateError' do
        expect { creator.send(:validate_stock!) }.to raise_error(Checkouts::Creator::StockUpdateError, /Missing inventory for movement/)
      end
    end
  end

  describe 'error classes' do
    it 'defines Error as base error class' do
      expect(Checkouts::Creator::Error).to be < StandardError
    end

    it 'defines CheckoutCreationError' do
      expect(Checkouts::Creator::CheckoutCreationError).to be < Checkouts::Creator::Error
    end

    it 'defines StockUpdateError' do
      expect(Checkouts::Creator::StockUpdateError).to be < Checkouts::Creator::Error
    end
  end
end
