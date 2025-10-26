class InventoriesController < BaseController
  def index
    scope = params[:q].present? ? current_client.inventories.search_by_keyword(params[:q]) : current_client.inventories
    scope = apply_sorting(scope)
    @pagy, @inventories = pagy(scope.includes(client_product_variant: :client_product))

    # Stock statistics
    @in_stock_count = current_client.inventories.in_stock.count
    @low_stock_count = current_client.inventories.low_stock.count
    @out_of_stock_count = current_client.inventories.out_of_stock.count

    respond_to do |format|
      format.html
      format.csv do
        export_inventories_to_csv(scope)
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

    redirect_to adjustments_inventories_path, notice: "Stock adjustments saved successfully."
  rescue => e
    redirect_to adjustments_inventories_path, alert: "Failed to save adjustments: #{e.message}"
  end

  private

  def export_inventories_to_csv(scope)
    exporter = Inventories::Exporter.new(inventories: scope, sort_by: params[:sort_by])
    csv_data = exporter.call!

    filename = "inventories_#{Date.current.strftime('%Y%m%d')}.csv"

    send_data csv_data,
              filename: filename,
              type: "text/csv",
              disposition: "attachment"
  rescue Inventories::Exporter::Error => e
    redirect_to inventories_path, alert: e.message
  end

  def apply_sorting(scope)
    case params[:sort_by]
    when "product_name_asc"
      scope.joins(client_product_variant: :client_product).order("client_products.name ASC")
    when "product_name_desc"
      scope.joins(client_product_variant: :client_product).order("client_products.name DESC")
    when "quantity_asc"
      scope.order(:quantity)
    when "quantity_desc"
      scope.order(quantity: :desc)
    else
      scope.order(:id) # Default sorting
    end
  end

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
