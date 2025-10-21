class AddCheckoutIdToInventoryMovement < ActiveRecord::Migration[8.0]
  def change
    add_reference :client_inventory_movements, :client_checkout, foreign_key: true, null: true
  end
end
