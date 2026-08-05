class AddOrderToCatalog < ActiveRecord::Migration[8.0]
  def up
    add_column :catalogs, :order, :integer, default: 0, null: false

    Catalog.reset_column_information
    Catalog.distinct.pluck(:client_id).each do |client_id|
      Catalog.where(client_id: client_id).order(:created_at, :id).each_with_index do |catalog, index|
        catalog.update_column(:order, index)
      end
    end
  end

  def down
    remove_column :catalogs, :order
  end
end
