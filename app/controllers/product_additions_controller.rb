class ProductAdditionsController < BaseController
  def new
    @addable_products = addable_products
    return if params[:product_id].blank?

    @product = @addable_products.find_by(id: params[:product_id])
    redirect_to new_product_addition_path, alert: "Product not available to add." if @product.nil?
  end

  def create
    product = addable_products.find_by(id: params[:product_id])

    if product
      ClientInventories::AddCatalogProduct.call!(
        client: current_client,
        user: current_user,
        product_id: product.id,
        variants_params: variants_params
      )
      redirect_to products_path, notice: "#{product.name} was added to your inventory."
    else
      redirect_to new_product_addition_path, alert: "Product not available to add."
    end
  rescue ClientInventories::AddCatalogProduct::AlreadyAddedError, ClientInventories::AddCatalogProduct::NoQuantityError => e
    redirect_to new_product_addition_path(product_id: product.id), alert: e.message
  end

  private

  def addable_products
    current_client.assigned_products
      .where.not(id: current_client.client_products.where.not(product_id: nil).select(:product_id))
      .includes(:drive_files, :product_colors)
  end

  def variants_params
    raw = params[:variants]
    raw.is_a?(ActionController::Parameters) ? raw : {}
  end
end
