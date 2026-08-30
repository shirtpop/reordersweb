class StorefrontController < BaseController
  def index
    @catalogs = current_client.browsable_catalogs.includes(:products, :client).to_a

    # Handle empty state - no catalogs assigned
    return if @catalogs.empty?

    # Determine selected catalog (from query param or default to first)
    @selected_catalog = if params[:catalog_id].present?
      @catalogs.find { |catalog| catalog.id == params[:catalog_id].to_i } || @catalogs.first
    else
      @catalogs.first
    end

    # Get products for selected catalog
    @products = @selected_catalog.products.includes(:drive_files, :product_colors)
  end
end
