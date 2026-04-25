class AddMinimumOrderToProductColors < ActiveRecord::Migration[8.0]
  def change
    add_column :product_colors, :minimum_order, :integer, default: 0, null: false
  end
end
