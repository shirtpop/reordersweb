class ApplicationController < ActionController::Base
  http_basic_authenticate_with name: Rails.application.credentials.dig(:http_basic_auth, :name),
                               password: Rails.application.credentials.dig(:http_basic_auth, :password) if Rails.env.staging?

  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
end
