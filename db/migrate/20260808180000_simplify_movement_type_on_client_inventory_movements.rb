class SimplifyMovementTypeOnClientInventoryMovements < ActiveRecord::Migration[8.0]
  def up
    execute "UPDATE client_inventory_movements SET quantity = ABS(quantity)"

    execute <<~SQL
      UPDATE client_inventory_movements
      SET movement_type = 'add'
      WHERE movement_type IN ('stock_in', 'return', 'restock', 'delivered_in')
    SQL

    execute <<~SQL
      UPDATE client_inventory_movements
      SET movement_type = 'subtract'
      WHERE movement_type IN ('stock_out', 'damaged', 'missing')
    SQL

    change_column_default :client_inventory_movements, :movement_type, "add"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
