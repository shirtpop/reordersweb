class CreateProductColorImages < ActiveRecord::Migration[8.0]
  def change
    create_table :product_color_images do |t|
      t.references :product_color, null: false, foreign_key: true
      t.integer :angle, null: false

      t.timestamps
    end

    add_index :product_color_images, [ :product_color_id, :angle ], unique: true
  end
end
