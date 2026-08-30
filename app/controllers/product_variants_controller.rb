class ProductVariantsController < BaseController
  before_action :set_product_variant, only: [ :delete_info, :destroy ]

  def index
    @product_variants = current_client.product_variants.includes(:client_product, :inventory)
    @product_variants = @product_variants.where(client_product_id: params[:product_id]) if params[:product_id].present?
  end

  def show
    @product_variant = current_client.product_variants.find_by(sku: params[:sku])

    render json: { error: "Product variant not found" }, status: :not_found unless @product_variant
  end

  def delete_info
    render partial: "inventories/products/variant_delete_info", locals: { variant: @product_variant }
  end

  def destroy
    product = @product_variant.client_product
    @product_variant.destroy!
    redirect_to product_path(product), notice: "Variant deleted."
  end

  private

  def set_product_variant
    @product_variant = current_client.product_variants.find_by!(sku: params[:sku])
  end
end
