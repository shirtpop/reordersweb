class LowStockMailer < ApplicationMailer
  def low_stock_alert
    @client_inventory = Client::Inventory.includes(client_product_variant: :client_product).find(params[:client_inventory_id])
    @variant = @client_inventory.client_product_variant
    @product = @variant.client_product
    @reorder_catalog = @product.reorder_catalog

    recipients = @client_inventory.client.users.role_client.where(active: true).pluck(:email)
    return if recipients.empty?

    mail to: recipients, subject: "Low stock alert: #{@product.name}"
  end
end
