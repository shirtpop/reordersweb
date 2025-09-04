require 'rails_helper'

RSpec.describe Orders::Creator do
  let(:product1) do
    create(:product,
      base_price: 100,
      minimum_order: 1,
      bulk_prices: [
        { "qty" => 5, "price" => 90 },
        { "qty" => 10, "price" => 80 }
      ])
  end

  let(:product2) do
    create(:product,
      base_price: 50,
      minimum_order: 1,
      bulk_prices: nil)
  end

  let(:order_item1) { build(:order_item, product: product1, quantity: 3) }
  let(:order_item2) { build(:order_item, product: product1, quantity: 7) }
  let(:order_item3) { build(:order_item, product: product2, quantity: 2) }

  let(:order) do
    build(:order, order_items: [ order_item1, order_item2, order_item3 ])
  end

  subject(:creator) { described_class.new(order: order) }

  describe "#call!" do
    context "when order is valid" do
      it "calculates total quantity and price, saves the order, and returns it" do
        expect(order).to receive(:save!).and_call_original

        result = creator.call!

        expect(result).to eq(order)
        expect(order.total_quantity).to eq(3 + 7 + 2) # 12
        # Price calculation:
        # product1 total qty = 3 + 7 = 10
        # bulk price for qty 10 = 80 (lowest price for qty <= 10)
        # total price for product1 = 80 * 10 = 800
        # product2 qty = 2, no bulk price, base_price = 50
        # total price for product2 = 50 * 2 = 100
        # total price = 800 + 100 = 900
        expect(order.price).to eq(900.0)
        expect(creator.success?).to be true
      end
    end

    context "when order has errors before saving" do
      before do
        order.errors.add(:base, "some error")
      end

      it "does not save the order and returns it" do
        expect(order).not_to receive(:save!)
        result = creator.call!
        expect(result).to eq(order)
        expect(creator.success?).to be false
      end
    end

    context "when save! raises ActiveRecord::RecordInvalid" do
      before do
        allow(order).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(order))
      end

      it "rescues and returns the order" do
        result = creator.call!
        expect(result).to eq(order)
        expect(creator.success?).to be false
      end
    end
  end

  describe "#price_for" do
    it "returns base_price if no bulk_prices" do
      expect(creator.send(:price_for, product2, 1)).to eq(product2.base_price.to_i)
    end

    it "returns correct bulk price for given quantity" do
      # qty less than first bulk price threshold
      expect(creator.send(:price_for, product1, 1)).to eq(product1.base_price.to_i)
      # qty equal to first bulk price threshold
      expect(creator.send(:price_for, product1, 5)).to eq(90.0)
      # qty between bulk price thresholds
      expect(creator.send(:price_for, product1, 7)).to eq(90.0)
      # qty equal to highest bulk price threshold
      expect(creator.send(:price_for, product1, 10)).to eq(80.0)
      # qty greater than highest bulk price threshold
      expect(creator.send(:price_for, product1, 15)).to eq(80.0)
    end
  end
end
