module Admin
  class DashboardController < BaseController
    def index
      @projects_count = Project.count
      @clients_count = Client.count
      @orders_count = nil
      @recent_users = User.order(created_at: :desc).limit(5)
    end
  end
end