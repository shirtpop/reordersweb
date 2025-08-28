class OrderMailer < ApplicationMailer
  def client_confirmation
    @order = Order.includes(:client, :project, order_items: [ :product ]).find(params[:order_id])
    @client = @order.client
    mail to: @client.users.first.email, subject: "Your order has been created"
  end

  def admin_notification
    @order = Order.includes(:client, :project, order_items: [ :product ]).find(params[:order_id])
    # If you have multiple admins, you can fetch from User.admin.pluck(:email)
    mail to: User.role_admin.first.email, subject: "New order created"
  end
end
