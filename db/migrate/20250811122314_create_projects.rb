class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.references :client, null: false, foreign_key: true
      t.string :name, null: false
      t.string :status, limit: 10, null: false, default: 'draft'

      t.timestamps
    end
  end
end
