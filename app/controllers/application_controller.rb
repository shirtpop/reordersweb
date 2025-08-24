class ApplicationController < ActionController::Base
  http_basic_authenticate_with name: 'shirtpop', password: 'awesome' if Rails.env.staging?

  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!

  def current_client
    @current_client ||= current_user.client
  end
end
