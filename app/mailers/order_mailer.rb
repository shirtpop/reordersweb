class OrderMailer < ApplicationMailer
  def client_confirmation
    @order = params[:order]
    @client = @order.client
    mail to: @client.users.first.email, subject: "Your order has been created"
  end

  def admin_notification
    @order = params[:order]
    # If you have multiple admins, you can fetch from User.admin.pluck(:email)
    mail to: User.role_admin.first.email, subject: "New order created"
  end
end
