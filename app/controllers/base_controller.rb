class BaseController < ApplicationController
  before_action :check_user

  def current_client
    @current_client ||= current_user.client
  end

  private

  def check_user
    unless current_user&.role_client?
      redirect_to admin_root_path, alert: "Access denied."
    end
  end
end
