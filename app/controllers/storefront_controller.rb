class StorefrontController < BaseController
  def index
    @catalogs = current_client.projects.active.includes(:products)

    # Handle empty state - no catalogs assigned
    return if @catalogs.empty?

    # Determine selected catalog (from query param or default to first)
    @selected_catalog = if params[:catalog_id].present?
      @catalogs.find_by(id: params[:catalog_id]) || @catalogs.first
    else
      @catalogs.first
    end

    # Get products for selected catalog
    @products = @selected_catalog.products.includes(:drive_files)

    # Get or create cart (draft order) for this catalog
    @cart = current_client.orders.in_cart.find_or_initialize_by(
      project_id: @selected_catalog.id,
      ordered_by: current_user
    )
  end
end
