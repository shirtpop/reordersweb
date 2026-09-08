class BaseController < ApplicationController
  before_action :check_user
  before_action :set_current_client
  before_action :block_demo_inventory_access
  before_action :check_inventories_access

  helper_method :current_client

  # Matched against controller_path (not controller_name) since several of these are
  # namespaced controllers whose bare controller_name collides with unrelated
  # controllers (e.g. Inventories::ProductsController#controller_name is "products",
  # same as the storefront's product-detail controller).
  INVENTORIES_ENABLED_CONTROLLER_PATHS = %w[
    inventories/dashboard
    inventories/products
    inventory_movements
    checkouts/items
    product_additions
  ].freeze

  DEMO_BLOCKED_CONTROLLER_PATHS = %w[
    inventories/dashboard
    inventories/products
    checkouts
    checkouts/items
    inventory_movements
    product_additions
    product_variants
  ].freeze

  def current_client
    @current_client
  end

  def check_inventories_access
    return true unless INVENTORIES_ENABLED_CONTROLLER_PATHS.include?(controller_path)

    unless @current_client.inventory_enabled
      redirect_to root_path, alert: "Inventory access is disabled."
    end
  end

  def block_demo_inventory_access
    return unless @current_client&.demo?
    return unless DEMO_BLOCKED_CONTROLLER_PATHS.include?(controller_path)

    redirect_to root_path, alert: "This is a trial account — inventory and receiving tools are disabled."
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
