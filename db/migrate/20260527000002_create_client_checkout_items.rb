class CreateClientCheckoutItems < ActiveRecord::Migration[8.0]
  def change
    create_table :client_checkout_items do |t|
      t.references :client_checkout, null: false, foreign_key: true
      t.references :client_inventory, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.timestamps
    end

    add_index :client_checkout_items, [:client_checkout_id, :client_inventory_id], unique: true,
              name: "idx_checkout_items_on_checkout_and_inventory"
  end
end
