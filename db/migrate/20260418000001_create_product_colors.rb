class CreateProductColors < ActiveRecord::Migration[8.0]
  def change
    create_table :product_colors do |t|
      t.references :product, null: false, foreign_key: true
      t.string :name, null: false
      t.string :hex_color

      t.timestamps
    end
  end
end
