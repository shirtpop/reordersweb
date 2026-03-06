module Admin
  class ClientProductAssignmentsController < BaseController
    before_action :set_client

    # JSON endpoint for copy-products feature
    def show
      products = @client.assigned_products.select(:id, :name, :colors)
      render json: { products: products.map { |p| { id: p.id, name: p.name, color_names: p.color_names } } }
    end

    private

    def set_client
      @client = Client.find(params[:client_id])
    end
  end
end
