class AddReceivedAtToOrder < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :received_at, :datetime, null: true
    add_reference :orders, :received_by, foreign_key: { to_table: :users }, null: true
  end
end
