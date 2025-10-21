class ProductVariantsController < BaseController
  def show
    @product_variant = current_client.product_variants.find_by(sku: params[:sku])
  end
end
