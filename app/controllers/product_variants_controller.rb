class ProductVariantsController < BaseController
  def index
    @product_variants = current_client.product_variants.includes(:client_product, :inventory)
    @product_variants = @product_variants.where(client_product_id: params[:product_id]) if params[:product_id].present?
  end

  def show
    @product_variant = current_client.product_variants.find_by(sku: params[:sku])

    render json: { error: "Product variant not found" }, status: :not_found unless @product_variant
  end
end
