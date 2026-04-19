class AddOrderNumberToOrders < ActiveRecord::Migration[8.0]
  def up
    add_column :orders, :order_number, :string
    add_index :orders, :order_number, unique: true

    # Backfill existing orders
    Order.order(:created_at, :id).each do |order|
      month_start = order.created_at.beginning_of_month
      month_end = order.created_at.end_of_month
      seq = Order.where(created_at: month_start..month_end)
                 .where("id <= ?", order.id)
                 .where.not(order_number: nil)
                 .count + 1
      date_str = order.created_at.strftime("%Y%m%d")
      order.update_column(:order_number, "O#{date_str}#{seq.to_s.rjust(4, '0')}")
    end

    change_column_null :orders, :order_number, false
  end

  def down
    remove_column :orders, :order_number
  end
end
