module Admin
  class ClientProductsController < BaseController
    before_action :set_client

    def index
      scope = params[:q].present? ? @client.client_products.search_by_name(params[:q]) : @client.client_products.order(created_at: :desc)

      @pagy, @products = pagy(scope)
    end

    def show
      @product = @client.client_products.includes(product_variants: :inventory).find(params[:id])
    end

    private

    def set_client
      @client = Client.find(params[:client_id])
    end
  end
end
