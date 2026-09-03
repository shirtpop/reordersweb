class AddDepartmentToClientCheckout < ActiveRecord::Migration[8.0]
  def change
    add_column :client_checkouts, :department, :string
  end
end
