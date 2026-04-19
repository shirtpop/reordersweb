class StorefrontController < BaseController
  def index
    @catalogs = current_client.catalogs.active.includes(:products)

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
  end
end
