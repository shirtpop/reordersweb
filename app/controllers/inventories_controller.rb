class InventoriesController < BaseController
  def index
    scope = params[:q].present? ? current_client.inventories.search_by_keyword(params[:q]) : current_client.inventories
    @pagy, @inventories = pagy(scope.includes(client_product_variant: :client_product))

    # Stock statistics
    @in_stock_count = current_client.inventories.in_stock.count
    @low_stock_count = current_client.inventories.low_stock.count
    @out_of_stock_count = current_client.inventories.out_of_stock.count
  end

  def adjustments; end

  def search_products
    @products = current_client.client_products
      .search_by_name(params[:q])
      .includes(:product_variants)
      .limit(10)
  end

  def save_adjustments
    ClientInventories::ApplyMovements.call!(user: current_user, movements_params: adjustments_params)

    redirect_to adjustments_inventories_path, notice: "Stock adjustments saved successfully."
  rescue => e
    redirect_to adjustments_inventories_path, alert: "Failed to save adjustments: #{e.message}"
  end

  def stock_outs; end

  private

  def set_inventory
    @inventory = current_client.inventories.find(params[:id])
  end

  def adjustments_params
    params.require(:adjustments).permit(
      :movement_type,
      product_variants: [ :product_variant_id, :product_variant_quantity ]
    )
  end
end
