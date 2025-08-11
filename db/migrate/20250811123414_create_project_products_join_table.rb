class CreateProjectProductsJoinTable < ActiveRecord::Migration[8.0]
  def change
    create_join_table :projects, :products do |t|
      t.index [:project_id, :product_id], unique: true
    end
  end
end
