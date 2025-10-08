class InventoryMovementsController < BaseController
  before_action :set_inventory

  def index
    @pagy, @inventory_movements = pagy(@inventory.inventory_movements.order(created_at: :desc))
    @product_variant = @inventory.client_product_variant
    @product = @product_variant.client_product
  end

  private

  def set_inventory
    @inventory = current_client.inventories.includes(client_product_variant: :client_product).find(params[:id])
  end
end
