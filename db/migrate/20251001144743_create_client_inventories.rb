class CreateClientInventories < ActiveRecord::Migration[8.0]
  def change
    create_table :client_inventories do |t|
      t.references :client, null: false, foreign_key: true
      t.references :client_product_variant, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 0

      t.timestamps
    end

    add_index :client_inventories, [ :client_id, :client_product_variant_id ], unique: true, name: "index_client_inventories_on_client_and_variant"
  end
end
