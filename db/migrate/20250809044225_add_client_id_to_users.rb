class AddClientIdToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :client, foreign_key: true
  end
end
