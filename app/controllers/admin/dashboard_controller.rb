module Admin
  class DashboardController < BaseController
    def index
      @users_count = User.count
      @recent_users = User.order(created_at: :desc).limit(5)
    end
  end
end