class CreateClientProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :client_products do |t|
      t.references :client, null: true, foreign_key: true
      t.references :product, null: true, foreign_key: true
      t.string :name

      t.timestamps
    end
  end
end
