class AddMinimumQuantityToClientInventories < ActiveRecord::Migration[8.0]
  def change
    add_column :client_inventories, :minimum_quantity, :integer, default: 10, null: false
  end
end
