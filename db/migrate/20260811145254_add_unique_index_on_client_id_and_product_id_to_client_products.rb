class AddUniqueIndexOnClientIdAndProductIdToClientProducts < ActiveRecord::Migration[8.0]
  def change
    add_index :client_products, [ :client_id, :product_id ], unique: true,
      name: "index_client_products_on_client_id_and_product_id", if_not_exists: true
  end
end
