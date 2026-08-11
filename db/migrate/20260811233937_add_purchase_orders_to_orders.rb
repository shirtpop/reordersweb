class AddPurchaseOrdersToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :purchase_order, :string, limit: 100
  end
end
