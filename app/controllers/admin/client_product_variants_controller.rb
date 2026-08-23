module Admin
  class ClientProductVariantsController < BaseController
    before_action :set_variant, only: [ :delete_info, :destroy ]

    def delete_info
      render partial: "admin/client_products/variant_delete_info", locals: { variant: @variant }
    end

    def destroy
      product = @variant.client_product
      @variant.destroy!
      redirect_to admin_client_product_path(product.client, product), notice: "Variant deleted."
    end

    private

    def set_variant
      @variant = Client::ProductVariant.joins(:client_product).where(client_products: { client_id: params[:client_id] }).find(params[:id])
    end
  end
end
