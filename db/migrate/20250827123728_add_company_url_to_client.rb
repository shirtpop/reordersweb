class AddCompanyUrlToClient < ActiveRecord::Migration[8.0]
  def change
    add_column :clients, :company_url, :string
  end
end
