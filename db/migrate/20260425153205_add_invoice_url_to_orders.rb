class AddInvoiceUrlToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :invoice_url, :string
  end
end
