class AddDashboardIndexesToOrders < ActiveRecord::Migration[8.0]
  def change
    # Index for date-range queries on dashboard
    add_index :orders, :created_at, if_not_exists: true

    # Composite indexes for status + date queries (common dashboard patterns)
    add_index :orders, [ :status, :created_at ], if_not_exists: true
    add_index :orders, [ :created_at, :status ], if_not_exists: true
  end
end
