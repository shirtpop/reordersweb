class BaseController < ApplicationController
  before_action :check_user
  before_action :force_password_change, if: :user_signed_in?

  def current_client
    @current_client ||= current_user.client
  end

  private

  def check_user
    unless current_user&.role_client?
      redirect_to admin_root_path, alert: "Access denied."
    end
  end

  def force_password_change
    return if devise_controller? && controller_name == "registrations"
    return unless current_user.role_client? && current_user.first_time_login?

    redirect_to edit_user_registration_path, alert: "Please change your password."
  end
end
