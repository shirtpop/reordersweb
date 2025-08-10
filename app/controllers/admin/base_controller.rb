module Admin
  class BaseController < ApplicationController
    layout 'admin'

    before_action :authenticate_user!
    before_action :check_admin

    private

    def check_admin
      unless current_user&.role_admin?
        redirect_to root_path, alert: 'Access denied.'
      end
    end
  end
end