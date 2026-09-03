class AddCheckoutItemsCountToClientCheckouts < ActiveRecord::Migration[8.0]
  def up
    add_column :client_checkouts, :checkout_items_count, :integer, default: 0, null: false

    execute <<~SQL
      UPDATE client_checkouts
      SET checkout_items_count = (
        SELECT COUNT(*) FROM client_checkout_items
        WHERE client_checkout_items.client_checkout_id = client_checkouts.id
      )
    SQL
  end

  def down
    remove_column :client_checkouts, :checkout_items_count
  end
end
