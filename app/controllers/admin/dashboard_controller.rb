module Admin
  class DashboardController < BaseController
    def index
      @projects_count = Project.count
      @clients_count = Client.count
      @orders_count = Order.count
      @current_revenue = Order.where(created_at: Time.zone.now.beginning_of_month..Time.zone.now.end_of_month).sum(:price)
      @recent_users = User.order(created_at: :desc).limit(5)
      @recent_orders = Order.order(created_at: :desc).limit(5)
      @recent_clients = Client.order(created_at: :desc).limit(5)
    end
  end
end