class Storefront::ProductsController < BaseController
  # Storefront product detail page (for ordering) — the "reorder" side. Kept separate
  # from Inventories::ProductsController (the client's own inventory-tracked products)
  # since the two are unrelated concerns that happen to both be "a product show page";
  # conflating them behind one action branching on params[:catalog_id] made a missing
  # catalog_id silently fall into the wrong (inventory) branch instead of failing here,
  # where it's rescued.
  def show
    # Find the catalog and product (admin Product, not Client::Product).
    # A main account can view its own catalogs plus every linked child's catalogs,
    # matching what the storefront index shows it.
    @catalog = Catalog.active.where(client_id: [ current_client.id, *current_client.children.ids ]).find(params[:catalog_id])
    @product = @catalog.products
                       .includes(:drive_files, product_colors: { product_color_images: :drive_files })
                       .find(params[:id])

    # Other active catalogs this same product is also assigned to, so the page can
    # surface a "you're viewing it under X, also available under Y" switcher instead
    # of silently ordering under whichever catalog happened to be linked to.
    @other_catalogs = current_client.catalogs_for_product(@product.id).where.not(id: @catalog.id)
  rescue ActiveRecord::RecordNotFound
    redirect_to storefront_path, alert: "Product not found or not available in your catalogs."
  end
end
