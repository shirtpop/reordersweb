class CreateClients < ActiveRecord::Migration[8.0]
  def change
    create_table :clients do |t|
      t.string :company_name
      t.string :personal_name
      t.string :phone_number
      t.references :address, foreign_key: { to_table: :addresses }
      t.references :shipping_address, foreign_key: { to_table: :addresses }

      t.timestamps
    end
  end
end
