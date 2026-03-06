class RenameProjectsToCatalogs < ActiveRecord::Migration[8.0]
  def change
    rename_table :projects, :catalogs
    rename_table :products_projects, :catalogs_products
    rename_column :orders, :project_id, :catalog_id
    rename_column :catalogs_products, :project_id, :catalog_id
  end
end
