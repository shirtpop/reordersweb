require "rails_helper"

RSpec.describe Order, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  describe "#set_order_number" do
    let(:client) do
      client = create(:client, :without_users)
      create(:user, :client, client: client)
      client
    end
    let(:product) { create(:product) }

    def build_order
      order = build(:order, client: client)
      order.order_items = [ build(:order_item, order: order, product: product) ]
      order.save!
      order
    end

    it "assigns sequential order numbers within the same month" do
      travel_to Time.zone.local(2026, 8, 1) do
        order1 = build_order
        order2 = build_order

        expect(order1.order_number).to eq("O202608010001")
        expect(order2.order_number).to eq("O202608010002")
      end
    end

    it "does not reuse a sequence number after earlier orders in the month are deleted" do
      travel_to Time.zone.local(2026, 8, 23) do
        orders = Array.new(10) { build_order }
        expect(orders.last.order_number).to eq("O202608230010")

        # Delete orders 1 through 9, keeping the 10th (whose number is still O202608230010)
        orders.first(9).each(&:destroy)

        new_order = build_order

        expect(new_order.order_number).to eq("O202608230011")
        expect(Order.count).to eq(2)
      end
    end

    it "keeps order_numbers unique even after repeated deletions mid-sequence" do
      travel_to Time.zone.local(2026, 8, 23) do
        3.times { build_order }
        Order.order(:id).limit(2).each(&:destroy)
        3.times { build_order }

        expect(Order.pluck(:order_number).uniq.size).to eq(Order.count)
      end
    end
  end
end
