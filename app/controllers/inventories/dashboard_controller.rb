class Inventories::DashboardController < BaseController
  def index
    scope = current_client.inventories.includes(client_product_variant: :client_product)
    scope = scope.search_by_keyword(params[:q]) if params[:q].present?
    scope = scope.sorted_by(params[:sort_by])

    respond_to do |format|
      format.html do
        @pagy, @inventories = pagy(scope, items: 20)
        @out_of_stock_count = current_client.inventories.out_of_stock.count
        @low_stock_count = current_client.inventories.low_stock.count
        @in_stock_count = current_client.inventories.count - @out_of_stock_count - @low_stock_count
      end
      format.csv do
        csv = Inventories::Exporter.new(inventories: scope, sort_by: params[:sort_by]).call!
        send_data csv, filename: "inventory-#{Time.current.strftime('%Y%m%d-%H%M%S')}.csv"
      end
    end
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

  def update
    inventory = current_client.inventories.find(params[:id])

    if inventory.update(minimum_quantity: params[:minimum_quantity])
      redirect_back fallback_location: products_path, notice: "Low stock threshold updated."
    else
      redirect_back fallback_location: products_path, alert: inventory.errors.full_messages.to_sentence
    end
  end

  private

  def adjustments_params
    params.require(:adjustments).permit(
      :movement_type,
      product_variants: [ :product_variant_id, :product_variant_quantity ]
    )
  end
end
