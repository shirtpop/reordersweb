class CreateClientProductVariants < ActiveRecord::Migration[8.0]
  def change
    create_table :client_product_variants do |t|
      t.references :client_product, null: false, foreign_key: true
      t.string :color, limit: 70
      t.string :size, limit: 30
      t.string :sku

      t.timestamps
    end

    add_index :client_product_variants, :sku, unique: true
  end
end
