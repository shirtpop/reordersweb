module Admin
  class ClientProductAdditionsController < BaseController
    before_action :set_client

    def new
      @addable_products = addable_products
      return if params[:product_id].blank?

      @product = @addable_products.find_by(id: params[:product_id])
      redirect_to new_admin_client_product_additions_path(@client), alert: "Product not available to add." if @product.nil?
    end

    def create
      product = addable_products.find_by(id: params[:product_id])

      if product
        ClientInventories::AddCatalogProduct.call!(
          client: @client,
          user: current_user,
          product_id: product.id,
          variants_params: variants_params
        )
        redirect_to new_admin_client_product_additions_path(@client), notice: "#{product.name} was added to #{@client.company_name}'s inventory."
      else
        redirect_to new_admin_client_product_additions_path(@client), alert: "Product not available to add."
      end
    rescue ClientInventories::AddCatalogProduct::AlreadyAddedError, ClientInventories::AddCatalogProduct::NoQuantityError => e
      redirect_to new_admin_client_product_additions_path(@client, product_id: product.id), alert: e.message
    end

    private

    def set_client
      @client = Client.find(params[:client_id])
    end

    def addable_products
      @client.assigned_products
        .where.not(id: @client.client_products.where.not(product_id: nil).select(:product_id))
        .includes(:drive_files, :product_colors)
    end

    def variants_params
      raw = params[:variants]
      raw.is_a?(ActionController::Parameters) ? raw : {}
    end
  end
end
