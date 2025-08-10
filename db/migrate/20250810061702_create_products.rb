class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name, null: false
      t.jsonb :price_info, default: {}
      t.string :sizes, array: true, default: []
      t.jsonb :colors, default: []
      t.string :image_url

      t.timestamps
    end

    add_index :products, :name
  end
end
