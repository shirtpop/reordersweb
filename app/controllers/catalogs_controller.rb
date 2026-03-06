class CatalogsController < BaseController
  def index
    # Redirect old catalogs list to new storefront
    redirect_to storefront_path
  end

  def show
    # Redirect old catalog detail to storefront with catalog filter
    redirect_to storefront_path(catalog_id: params[:id])
  end
end
