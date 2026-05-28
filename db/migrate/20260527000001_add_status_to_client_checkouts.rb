class AddStatusToClientCheckouts < ActiveRecord::Migration[8.0]
  def change
    add_column :client_checkouts, :status, :string, null: false, default: "confirmed"
    add_index :client_checkouts, :status
  end
end
