module Admin
  class CatalogsController < BaseController
    before_action :set_catalog, only: [ :edit, :show, :update, :destroy ]

    def index
      scope = params[:q].present? ? Catalog.search_by_keyword(params[:q]) : Catalog.includes(:client).order(created_at: :desc)
      @pagy, @catalogs = pagy(scope)
    end

    def show; end

    def new
      @catalog = Catalog.new
    end

    def create
      @catalog = Catalog.new(catalog_params)

      if @catalog.save
        redirect_to admin_catalogs_path, notice: "Catalog was successfully created."
      else
        render :new
      end
    end

    def edit; end

    def update
      if @catalog.update(catalog_params)
        update_catalog_products
        redirect_to admin_catalogs_path, notice: "Catalog was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      @catalog.destroy!
      redirect_to admin_catalogs_path, notice: "Catalog was successfully deleted."
    end

    private

    def set_catalog
      @catalog = Catalog.find(params[:id])
    end

    def catalog_params
      params.require(:catalog).permit(:name, :status, :client_id, :description, product_ids: [])
    end

    def update_catalog_products
      return unless params[:catalog][:product_ids]

      # Get the selected product IDs, filtering out empty values
      selected_product_ids = params[:catalog][:product_ids].reject(&:blank?).map(&:to_i)

      # Get current product IDs
      current_product_ids = @catalog.product_ids

      # Remove products that are no longer selected
      products_to_remove = current_product_ids - selected_product_ids
      if products_to_remove.any?
        @catalog.catalogs_products.where(product_id: products_to_remove).destroy_all
      end

      # Add new products
      products_to_add = selected_product_ids - current_product_ids
      products_to_add.each do |product_id|
        @catalog.catalogs_products.create!(product_id: product_id)
      end
    end
  end
end
