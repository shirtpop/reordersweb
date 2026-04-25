class AddProductColorIdToOrderItems < ActiveRecord::Migration[8.0]
  def change
    add_reference :order_items, :product_color, null: true, foreign_key: true
  end
end
