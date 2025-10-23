require 'rails_helper'

RSpec.describe Orders::Receiver do
  describe '.call!' do
    let(:order) { create(:order) }
    let(:client) { order.client }
    let(:user) { client.users.first }
    it 'calls the instance method' do
      receiver = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(receiver)
      allow(receiver).to receive(:call!)

      described_class.call!(order: order, user: user)

      aggregate_failures do
        expect(described_class).to have_received(:new).with(order: order, user: user)
        expect(receiver).to have_received(:call!)
      end
    end
  end

  describe '#call!' do
    context 'when receiving an order successfully' do
      let(:order) { create(:order) }
      let(:client) { order.client }
      let(:user) { client.users.first }
      let(:product) { order.project.products.first }
      it 'marks order as received' do
        described_class.call!(order: order, user: user)

        order.reload
        aggregate_failures do
          expect(order.received_at).to be_present
          expect(order.received_by_id).to eq(user.id)
        end
      end

      context 'when client product and product variants do not exist' do
        it 'creates client product and product variants' do
          expect {
            described_class.call!(order: order, user: user)
          }.to change(Client::Product, :count).by(order.order_items.count)

          client_product = Client::Product.last
          aggregate_failures do
            expect(client_product.client).to eq(client)
            expect(client_product.admin_product).to eq(product)
            expect(client_product.name).to eq(product.name)
            expect(client_product.product_variants.count).to eq(order.order_items.count)
            expect(client_product.product_variants.first.color).to eq(order.order_items.first.color)
            expect(client_product.product_variants.first.size).to eq(order.order_items.first.size)
            expect(client_product.product_variants.first.sku).to be_present
          end
        end

        it 'creates inventory and sets quantity' do
          expect {
            described_class.call!(order: order, user: user)
          }.to change(Client::Inventory, :count).by(order.order_items.count)

          inventory = Client::Inventory.last
          aggregate_failures do
            expect(inventory.client).to eq(client)
            expect(inventory.quantity).to eq(order.order_items.last.quantity)
          end
        end

        it 'creates inventory movement for each order item' do
          expect {
            described_class.call!(order: order, user: user)
          }.to change(Client::InventoryMovement, :count).by(order.order_items.count)

          aggregate_failures do
            order.order_items.each do |item|
              movement = Client::InventoryMovement.find_by(order_item: item)
              expect(movement).to be_present
              expect(movement.movement_type).to eq('delivered_in')
              expect(movement.quantity).to eq(item.quantity)
              expect(movement.user).to eq(user)
            end
          end
        end
      end

      context 'when client product and product variants exist' do
        let(:client_product) { create(:client_product, client: client, admin_product: product, name: product.name) }
        let(:client_product_variant) { create(:client_product_variant, client_product: client_product, color: order.order_items.first.color, size: order.order_items.first.size) }
        let!(:inventory) { create(:client_inventory, client: client, client_product_variant: client_product_variant, quantity: order.order_items.first.quantity) }
        it 'uses existing client product' do
          expect {
            described_class.call!(order: order, user: user)
          }.not_to change(Client::Product, :count)
        end
        it 'uses existing client product variant' do
          expect {
            described_class.call!(order: order, user: user)
          }.not_to change(Client::ProductVariant, :count)
        end

        it 'uses existing inventory if it exists' do
          expect {
            described_class.call!(order: order, user: user)
          }.not_to change(Client::Inventory, :count)
        end

        it 'increments inventory quantity for each order item' do
          described_class.call!(order: order, user: user)

          initial_quantity = inventory.quantity
          inventory.reload
          expected_quantity = initial_quantity + order.order_items.first.quantity
          expect(inventory.quantity).to eq(expected_quantity)
        end
      end
    end

    context 'when an error occurs during processing' do
      let(:order) { create(:order) }
      let(:user) { order.client.users.first }

      before do
        allow_any_instance_of(Client::Inventory).to receive(:increment!).and_raise(StandardError, 'Database error')
      end

      it 'rolls back the entire transaction' do
        initial_inventory_count = Client::Inventory.count
        initial_movement_count = Client::InventoryMovement.count

        expect {
          described_class.call!(order: order, user: user)
        }.to raise_error(StandardError, 'Database error')

        expect(Client::Inventory.count).to eq(initial_inventory_count)
        expect(Client::InventoryMovement.count).to eq(initial_movement_count)
        expect(order.reload.received_at).to be_nil
      end
    end
  end
end
