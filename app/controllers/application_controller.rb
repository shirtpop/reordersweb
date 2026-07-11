class ApplicationController < ActionController::Base
  http_basic_authenticate_with name: Rails.application.credentials.dig(:http_basic_auth, :name),
                               password: Rails.application.credentials.dig(:http_basic_auth, :password) if Rails.env.staging?

  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern unless Rails.env.test?

  before_action :authenticate_user!
  before_action :force_password_change, if: :user_signed_in?

  helper_method :cart_items_count, :checkout_basket_count, :current_draft_checkout

  def cart_items_count
    @cart_items_count ||= current_user&.in_cart_order&.order_items&.sum(:quantity) || 0
  end

  def checkout_basket_count
    @checkout_basket_count ||= current_draft_checkout&.checkout_items&.sum(:quantity) || 0
  end

  def current_draft_checkout
    @current_draft_checkout ||= current_user&.client&.checkouts&.find_by(status: :draft, user: current_user)
  end

  private

  def force_password_change
    return if devise_controller? && controller_name == "registrations"
    return if user_masquerade?
    return unless current_user.role_client? && current_user.first_time_login?

    redirect_to edit_user_registration_path, alert: "Please change your password."
  end
end
