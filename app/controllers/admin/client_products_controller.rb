module Admin
  class ClientProductsController < BaseController
    before_action :set_client
    before_action :set_product, only: [ :show, :delete_info, :destroy ]

    def index
      scope = params[:q].present? ? @client.client_products.search_by_name(params[:q]) : @client.client_products.order(created_at: :desc)

      @pagy, @products = pagy(scope)
    end

    def show; end

    def delete_info
      render partial: "delete_info", locals: { product: @product, impact: @product.delete_impact }
    end

    def destroy
      @product.destroy!
      redirect_to admin_client_products_path(@client, format: :html), notice: "Product deleted."
    end

    private

    def set_client
      @client = Client.find(params[:client_id])
    end

    def set_product
      @product = @client.client_products.includes(product_variants: :inventory).find(params[:id])
    end
  end
end
