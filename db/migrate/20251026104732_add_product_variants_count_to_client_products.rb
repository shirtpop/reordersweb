class AddProductVariantsCountToClientProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :client_products, :product_variants_count, :integer, default: 0
  end
end
