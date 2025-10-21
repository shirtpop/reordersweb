class CreateClientCheckouts < ActiveRecord::Migration[8.0]
  def change
    create_table :client_checkouts do |t|
      t.references :client, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :recipient_email
      t.string :recipient_first_name
      t.string :recipient_last_name
      t.text :notes
      t.timestamps
    end
  end
end
