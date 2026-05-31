class BaseController < ApplicationController
  before_action :check_user
  before_action :set_current_client
  before_action :check_inventories_access
  before_action :cart_items_count
  before_action :checkout_basket_count

  INVENTORIES_ENABLED_CONTROLLER = [ "inventories", "inventory_movements", "items" ].freeze

  def current_client
    @current_client
  end

  def cart_items_count
    @cart_items_count ||= current_user&.in_cart_order&.order_items&.sum(:quantity) || 0
  end

  def checkout_basket_count
    @checkout_basket_count ||= begin
      draft = current_client&.checkouts&.find_by(status: :draft, user: current_user)
      draft&.checkout_items&.sum(:quantity) || 0
    end
  end
  helper_method :cart_items_count, :checkout_basket_count

  def checkout_basket_count
    @checkout_basket_count ||= begin
      draft = current_client&.checkouts&.find_by(status: :draft, user: current_user)
      draft&.checkout_items&.sum(:quantity) || 0
    end
  end
  helper_method :checkout_basket_count

  def check_inventories_access
    return true unless INVENTORIES_ENABLED_CONTROLLER.include?(controller_name)

    unless @current_client.inventory_enabled
      redirect_to root_path, alert: "Inventory access is disabled."
    end
  end

  private

  def check_user
    unless current_user&.role_client?
      redirect_to admin_root_path, alert: "Access denied."
    end
  end

  def set_current_client
    @current_client ||= current_user.client
  end
end
