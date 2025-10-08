class AddClientInventoryEnabled < ActiveRecord::Migration[8.0]
  def change
    add_column :clients, :inventory_enabled, :boolean, default: false
  end
end
