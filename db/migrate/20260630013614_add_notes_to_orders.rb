class AddNotesToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :notes, :text
  end
end
