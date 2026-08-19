class AddParentIdToClient < ActiveRecord::Migration[8.0]
  def change
    add_reference :clients, :parent, foreign_key: { to_table: :clients }, index: true
  end
end
