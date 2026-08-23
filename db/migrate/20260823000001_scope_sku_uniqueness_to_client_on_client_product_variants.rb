class ScopeSkuUniquenessToClientOnClientProductVariants < ActiveRecord::Migration[8.0]
  def up
    add_column :client_product_variants, :client_id, :bigint

    execute <<~SQL
      UPDATE client_product_variants
      SET client_id = client_products.client_id
      FROM client_products
      WHERE client_products.id = client_product_variants.client_product_id
    SQL

    change_column_null :client_product_variants, :client_id, false

    add_foreign_key :client_product_variants, :clients

    remove_index :client_product_variants, :sku, unique: true, name: "index_client_product_variants_on_sku"
    add_index :client_product_variants, [ :client_id, :sku ], unique: true,
      name: "index_client_product_variants_on_client_id_and_sku"
  end

  def down
    add_index :client_product_variants, :sku, unique: true, name: "index_client_product_variants_on_sku"
    remove_index :client_product_variants, name: "index_client_product_variants_on_client_id_and_sku"

    remove_foreign_key :client_product_variants, :clients
    remove_column :client_product_variants, :client_id
  end
end
