class ApplicationController < ActionController::Base
  http_basic_authenticate_with name: "shirtpop", password: "awesome" if Rails.env.staging?

  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  before_action :force_password_change, if: :user_signed_in?

  def current_client
    @current_client ||= current_user.client
  end

  private

  def force_password_change
    return if devise_controller? && controller_name == "registrations"
    return unless current_user.role_client? && current_user.first_time_login?

    redirect_to edit_user_registration_path, alert: "Please change your password."
  end
end
