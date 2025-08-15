class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :client, foreign_key: true
      t.references :project, foreign_key: true
      t.date :delivery_date
      t.decimal :price, precision: 10, scale: 2, default: 0.0
      t.integer :total_quantity, default: 0

      t.timestamps
    end
  end
end
