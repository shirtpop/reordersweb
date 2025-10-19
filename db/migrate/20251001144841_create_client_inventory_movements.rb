class CreateClientInventoryMovements < ActiveRecord::Migration[8.0]
  def change
    create_table :client_inventory_movements do |t|
      t.references :client_inventory, null: false, foreign_key: { to_table: :client_inventories }
      t.references :order_item, null: true, foreign_key: { to_table: :order_items }
      t.references :user, null: true, foreign_key: { to_table: :users }
      t.string :movement_type, null: false, limit: 20, default: "in"
      t.integer :quantity, null: false
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :client_inventory_movements, :movement_type
  end
end
