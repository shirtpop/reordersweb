class StorefrontController < BaseController
  def index
    @children = current_client.children.to_a

    # A client with linked child accounts (e.g. a group's main account) sees its own
    # catalogs plus every linked child's catalogs, combined. A child never sees its
    # parent's catalogs, since @children is always empty for a child account.
    @catalogs = Catalog.active.ordered
      .where(client_id: [ current_client.id, *@children.map(&:id) ])
      .includes(:products, :client)
      .to_a

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

    # Group catalogs by the company they belong to, so the main account's sidebar
    # can categorize them by Kitchen / Spa / Campo instead of one flat list.
    @catalog_groups = build_catalog_groups if @children.any?
  end

  private

  def build_catalog_groups
    catalogs_by_owner_id = @catalogs.group_by(&:client_id)

    ([ current_client ] + @children).filter_map do |owner|
      owner_catalogs = catalogs_by_owner_id[owner.id]
      [ owner, owner_catalogs ] if owner_catalogs.present?
    end
  end
end
