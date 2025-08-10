module Admin
  class DashboardController < BaseController
    def index
      @users_count = User.count
      @recent_users = User.order(created_at: :desc).limit(5)
      @clients_count = Client.count
      @orders_count = nil
    end
  end
end