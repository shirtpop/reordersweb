module Admin
  class DashboardController < BaseController
    def index
      @catalogs_count = Catalog.count
      @clients_count = Client.count
      @orders_count = Order.count
      @current_revenue = Order.where(created_at: Time.zone.now.beginning_of_month..Time.zone.now.end_of_month).sum(:price)
      @recent_users = User.order(created_at: :desc).limit(5)
      @recent_orders = Order.order(created_at: :desc).limit(5)
      @recent_clients = Client.order(created_at: :desc).limit(5)
      @pending_receipt_orders = Order.pending_receipt.includes(:client).order(delivery_date: :asc).limit(20)
    end
  end
end
