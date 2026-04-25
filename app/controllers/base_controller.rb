class BaseController < ApplicationController
  before_action :check_user
  before_action :set_current_client
  before_action :check_inventories_access
  before_action :cart_items_count

  INVENTORIES_ENABLED_CONTROLLER = [ "inventories", "inventory_movements" ]

  def current_client
    @current_client
  end

  def cart_items_count
    @cart_items_count ||= current_user&.in_cart_order&.order_items&.sum(:quantity) || 0
  end

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
