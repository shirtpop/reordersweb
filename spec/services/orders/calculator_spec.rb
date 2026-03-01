require 'rails_helper'

RSpec.describe Orders::Calculator do
  let(:client) { create(:client) }
  let(:project) { create(:project, client: client) }

  # Product with base price only
  let(:simple_product) do
    create(:product,
      name: "Simple T-Shirt",
      price_info: {
        base_price: 10.0,
        minimum_order: 1,
        bulk_prices: nil
      }
    )
  end

  # Product with bulk pricing
  let(:bulk_product) do
    create(:product,
      name: "Bulk T-Shirt",
      price_info: {
        base_price: 15.0,
        minimum_order: 1,
        bulk_prices: [
          { "qty" => 10, "price" => 12.0 },
          { "qty" => 50, "price" => 10.0 },
          { "qty" => 100, "price" => 8.0 }
        ]
      }
    )
  end

  # Create order without default items (we'll add them in each test)
  let(:order) do
    build(:order, client: client, project: project, status: :cart).tap do |o|
      o.order_items = []  # Clear default items from factory
      o.save!(validate: false)  # Skip validation that requires order_items
    end
  end
  # Reload order to pick up any items added in before blocks
  let(:calculator) { described_class.new(order: order.reload) }

  describe '#total_quantity' do
    context 'with single product order' do
      before do
        create(:order_item, order: order, product: simple_product, quantity: 5, size: "M", color: "Blue")
        create(:order_item, order: order, product: simple_product, quantity: 3, size: "L", color: "Red")
      end

      it 'returns the sum of all order item quantities' do
        expect(calculator.total_quantity).to eq(8)
      end
    end

    context 'with multiple products' do
      before do
        create(:order_item, order: order, product: simple_product, quantity: 5, size: "M", color: "Blue")
        create(:order_item, order: order, product: bulk_product, quantity: 10, size: "L", color: "Red")
      end

      it 'returns the sum of all order item quantities' do
        expect(calculator.total_quantity).to eq(15)
      end
    end

    context 'with no items' do
      it 'returns 0' do
        expect(calculator.total_quantity).to eq(0)
      end
    end
  end

  describe '#total_price' do
    context 'with simple product (no bulk pricing)' do
      before do
        create(:order_item, order: order, product: simple_product, quantity: 5, size: "M", color: "Blue")
        create(:order_item, order: order, product: simple_product, quantity: 3, size: "L", color: "Red")
      end

      it 'calculates total using base price' do
        # 8 items * $10 = $80
        expect(calculator.total_price).to eq(80.0)
      end
    end

    context 'with bulk pricing - below first threshold' do
      before do
        # Total: 5 items (below 10)
        create(:order_item, order: order, product: bulk_product, quantity: 5, size: "M", color: "Blue")
      end

      it 'uses base price when quantity is below bulk threshold' do
        # 5 items * $15 (base price) = $75
        expect(calculator.total_price).to eq(75.0)
      end
    end

    context 'with bulk pricing - at first threshold' do
      before do
        # Total: 10 items (at first threshold)
        create(:order_item, order: order, product: bulk_product, quantity: 6, size: "M", color: "Blue")
        create(:order_item, order: order, product: bulk_product, quantity: 4, size: "L", color: "Red")
      end

      it 'applies first bulk price' do
        # 10 items * $12 = $120
        expect(calculator.total_price).to eq(120.0)
      end
    end

    context 'with bulk pricing - at middle threshold' do
      before do
        # Total: 50 items
        create(:order_item, order: order, product: bulk_product, quantity: 30, size: "M", color: "Blue")
        create(:order_item, order: order, product: bulk_product, quantity: 20, size: "L", color: "Red")
      end

      it 'applies second bulk price' do
        # 50 items * $10 = $500
        expect(calculator.total_price).to eq(500.0)
      end
    end

    context 'with bulk pricing - at highest threshold' do
      before do
        # Total: 100 items
        create(:order_item, order: order, product: bulk_product, quantity: 100, size: "M", color: "Blue")
      end

      it 'applies lowest bulk price' do
        # 100 items * $8 = $800
        expect(calculator.total_price).to eq(800.0)
      end
    end

    context 'with multiple products mixed' do
      before do
        # Simple product: 5 items * $10 = $50
        create(:order_item, order: order, product: simple_product, quantity: 5, size: "M", color: "Blue")

        # Bulk product: 50 items * $10 = $500
        create(:order_item, order: order, product: bulk_product, quantity: 30, size: "L", color: "Red")
        create(:order_item, order: order, product: bulk_product, quantity: 20, size: "XL", color: "Green")
      end

      it 'calculates correct total for mixed products' do
        # Total: $50 + $500 = $550
        expect(calculator.total_price).to eq(550.0)
      end
    end

    context 'with no items' do
      it 'returns 0' do
        expect(calculator.total_price).to eq(0)
      end
    end
  end

  describe '#breakdown' do
    before do
      create(:order_item, order: order, product: simple_product, quantity: 5, size: "M", color: "Blue")
      create(:order_item, order: order, product: simple_product, quantity: 3, size: "L", color: "Red")
      create(:order_item, order: order, product: bulk_product, quantity: 30, size: "M", color: "Green")
      create(:order_item, order: order, product: bulk_product, quantity: 20, size: "L", color: "Yellow")
    end

    it 'returns breakdown by product' do
      breakdown = calculator.breakdown

      expect(breakdown).to be_an(Array)
      expect(breakdown.length).to eq(2)
    end

    it 'includes correct details for each product' do
      breakdown = calculator.breakdown

      simple_breakdown = breakdown.find { |b| b[:product] == simple_product }
      bulk_breakdown = breakdown.find { |b| b[:product] == bulk_product }

      # Simple product breakdown
      expect(simple_breakdown[:quantity]).to eq(8)
      expect(simple_breakdown[:unit_price]).to eq(10.0)
      expect(simple_breakdown[:subtotal]).to eq(80.0)
      expect(simple_breakdown[:items].length).to eq(2)

      # Bulk product breakdown (50 items at $10 bulk price)
      expect(bulk_breakdown[:quantity]).to eq(50)
      expect(bulk_breakdown[:unit_price]).to eq(10.0)
      expect(bulk_breakdown[:subtotal]).to eq(500.0)
      expect(bulk_breakdown[:items].length).to eq(2)
    end
  end
end
