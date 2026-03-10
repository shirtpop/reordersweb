class AddSubmittedAtToOrders < ActiveRecord::Migration[8.0]
  def change
    # Add submitted_at timestamp column
    add_column :orders, :submitted_at, :datetime

    # Remove old indexes based on created_at
    remove_index :orders, :created_at, if_exists: true
    remove_index :orders, [ :status, :created_at ], if_exists: true
    remove_index :orders, [ :created_at, :status ], if_exists: true

    # Add new indexes based on submitted_at
    add_index :orders, :submitted_at, if_not_exists: true
    add_index :orders, [ :status, :submitted_at ], if_not_exists: true
    add_index :orders, [ :submitted_at, :status ], if_not_exists: true

    # Backfill submitted_at for existing submitted orders
    # Use updated_at as a proxy for when they were submitted
    reversible do |dir|
      dir.up do
        execute <<-SQL.squish
          UPDATE orders
          SET submitted_at = updated_at
          WHERE status != 'cart' AND submitted_at IS NULL
        SQL
      end
    end
  end
end
