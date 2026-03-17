class InventoriesController < BaseController
  def index
    redirect_to products_path
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

    redirect_back_or_to adjustments_inventories_path, notice: "Stock adjustments saved successfully."
  rescue => e
    redirect_back_or_to adjustments_inventories_path, alert: "Failed to save adjustments: #{e.message}"
  end

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
