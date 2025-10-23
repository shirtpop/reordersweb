require 'rails_helper'

RSpec.describe ClientInventories::ApplyMovements do
  let(:client) { create(:client) }
  let(:user) { create(:user, :client, client: client) }
  let(:client_product) { create(:client_product, client: client) }
  let(:product_variant1) { create(:client_product_variant, client_product: client_product) }
  let(:product_variant2) { create(:client_product_variant, client_product: client_product) }

  let(:movements_params) do
    {
      movement_type: 'stock_in',
      product_variants: [
        {
          product_variant_id: product_variant1.id,
          product_variant_quantity: 10
        },
        {
          product_variant_id: product_variant2.id,
          product_variant_quantity: 5
        }
      ]
    }
  end

  describe '.call!' do
    it 'calls the instance method' do
      service = instance_double(described_class)
      allow(described_class).to receive(:new).with(user: user, movements_params: movements_params).and_return(service)
      expect(service).to receive(:call!)

      described_class.call!(user: user, movements_params: movements_params)
    end
  end

  describe '#call!' do
    context 'with valid parameters' do
      it 'applies movements to all product variants' do
        expect { described_class.call!(user: user, movements_params: movements_params) }
          .to change { Client::InventoryMovement.count }.by(2)
      end

      it 'creates inventory records for variants' do
        expect { described_class.call!(user: user, movements_params: movements_params) }
          .to change { Client::Inventory.count }.by(2)
      end

      it 'updates inventory quantities correctly' do
        described_class.call!(user: user, movements_params: movements_params)

        inventory1 = Client::Inventory.find_by(client_product_variant: product_variant1)
        inventory2 = Client::Inventory.find_by(client_product_variant: product_variant2)

        expect(inventory1.quantity).to eq(10)
        expect(inventory2.quantity).to eq(5)
      end

      it 'creates inventory movements with correct attributes' do
        described_class.call!(user: user, movements_params: movements_params)

        movement1 = Client::InventoryMovement.find_by(client_inventory: Client::Inventory.find_by(client_product_variant: product_variant1))
        movement2 = Client::InventoryMovement.find_by(client_inventory: Client::Inventory.find_by(client_product_variant: product_variant2))

        expect(movement1.movement_type).to eq('stock_in')
        expect(movement1.quantity).to eq(10)
        expect(movement1.user).to eq(user)

        expect(movement2.movement_type).to eq('stock_in')
        expect(movement2.quantity).to eq(5)
        expect(movement2.user).to eq(user)
      end
    end

    context 'with increase movements' do
      Client::InventoryMovement::INCREASE_MOVEMENTS.each do |movement_type|
        it "handles #{movement_type} movement correctly" do
          params = movements_params.merge(movement_type: movement_type.to_s)

          expect { described_class.call!(user: user, movements_params: params) }
            .to change { Client::InventoryMovement.count }.by(2)
        end
      end
    end

    context 'with decrease movements' do
      Client::InventoryMovement::DECREASE_MOVEMENTS.each do |movement_type|
        it "handles #{movement_type} movement correctly" do
          # First add some stock
          described_class.call!(user: user, movements_params: movements_params)

          # Then decrease
          decrease_params = movements_params.merge(movement_type: movement_type.to_s)
          expect { described_class.call!(user: user, movements_params: decrease_params) }
            .to change { Client::InventoryMovement.count }.by(2)
        end
      end
    end

    context 'with existing inventory' do
      let!(:existing_inventory1) { create(:client_inventory, client: client, client_product_variant: product_variant1, quantity: 5) }
      let!(:existing_inventory2) { create(:client_inventory, client: client, client_product_variant: product_variant2, quantity: 5) }

      it 'updates existing inventory instead of creating new one' do
        expect { described_class.call!(user: user, movements_params: movements_params) }
          .not_to change { Client::Inventory.count }
      end

      it 'increments existing inventory quantity' do
        described_class.call!(user: user, movements_params: movements_params)

        existing_inventory1.reload
        existing_inventory2.reload
        aggregate_failures do
          expect(existing_inventory1.quantity).to eq(15) # 5 + 10
          expect(existing_inventory2.quantity).to eq(10) # 5 + 5
        end
      end
    end

    context 'with empty product_variants' do
      let(:empty_params) { { movement_type: 'stock_in', product_variants: [] } }

      it 'does not create any movements' do
        expect { described_class.call!(user: user, movements_params: empty_params) }
          .not_to change { Client::InventoryMovement.count }
      end
    end

    context 'with nil product_variants' do
      let(:nil_params) { { movement_type: 'stock_in' } }

      it 'does not create any movements' do
        expect { described_class.call!(user: user, movements_params: nil_params) }
          .not_to change { Client::InventoryMovement.count }
      end
    end

    context 'with invalid movement type' do
      let(:invalid_params) { movements_params.merge(movement_type: 'invalid_type') }

      it 'raises ArgumentError' do
        expect { described_class.call!(user: user, movements_params: invalid_params) }
          .to raise_error(ArgumentError, "'invalid_type' is not a valid movement_type")
      end
    end

    context 'with database errors' do
      before do
        allow(Client::Inventory).to receive(:find_or_create_by!).and_raise(ActiveRecord::RecordInvalid.new(Client::Inventory.new))
      end

      it 'raises InvalidRecordError' do
        expect { described_class.call!(user: user, movements_params: movements_params) }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'with concurrent access' do
      it 'handles RecordNotUnique errors with retry' do
        allow(Client::Inventory).to receive(:find_or_create_by!)
          .and_raise(ActiveRecord::RecordNotUnique.new('Duplicate entry'))
          .once
        allow(Client::Inventory).to receive(:find_or_create_by!).and_call_original

        expect { described_class.call!(user: user, movements_params: movements_params) }
          .not_to raise_error
      end
    end

    context 'transaction rollback' do
      it 'rolls back all changes on error' do
        allow(Client::Inventory).to receive(:find_or_create_by!).and_raise(StandardError.new('Test error'))

        expect { described_class.call!(user: user, movements_params: movements_params) }
          .to raise_error(StandardError, 'Test error')

        initial_movement_count = Client::InventoryMovement.count
        initial_inventory_count = Client::Inventory.count

        aggregate_failures do
          expect(Client::InventoryMovement.count).to eq(initial_movement_count)
          expect(Client::Inventory.count).to eq(initial_inventory_count)
        end
      end
    end
  end
end
