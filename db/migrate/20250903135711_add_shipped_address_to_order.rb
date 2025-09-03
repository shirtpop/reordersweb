class AddShippedAddressToOrder < ActiveRecord::Migration[8.0]
  def change
    add_reference :orders, :shipped_to, foreign_key: { to_table: :addresses }
  end
end
