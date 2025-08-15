module Admin
  class ProductsController < BaseController
    before_action :set_product, only: [:edit, :show, :update, :destroy]

    def index
      scope = params[:q].present? ? Product.search_by_name(params[:q]) : Product.order(created_at: :desc)
      @pagy, @products = pagy(scope)
    end

    def show; end

    def new
      @product = Product.new
    end

    def create
      @product = Product.new(product_params)

      if @product.save
        redirect_to admin_products_path, notice: "Product was successfully created."
      else
        render :new
      end
    end

    def edit; end

    def update
      if @product.update(product_params)
        redirect_to admin_products_path, notice: "Product was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      @product.destroy!
      redirect_to admin_products_path, notice: "Product was successfully deleted."
    end

    private

    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(
        :name, :image_urls, :description, :minimum_order, :base_price,
        sizes: [],
        bulk_prices: [:qty, :price],
        colors: [:name, :hex_color]
      )
    end
  end
end
