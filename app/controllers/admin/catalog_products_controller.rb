module Admin
  class CatalogProductsController < BaseController
    before_action :set_client
    before_action :set_catalog

    def update
      product_ids = Array(params[:product_ids]).map(&:to_i).uniq

      ActiveRecord::Base.transaction do
        current_ids = @catalog.product_ids
        to_add = product_ids - current_ids
        to_remove = current_ids - product_ids

        CatalogsProduct.where(catalog: @catalog, product_id: to_remove).delete_all if to_remove.any?

        to_add.each do |pid|
          CatalogsProduct.create!(catalog: @catalog, product_id: pid)
        end
      end

      respond_to do |format|
        format.turbo_stream do
          catalogs = @client.catalogs.includes(:products).order(created_at: :desc)
          render turbo_stream: turbo_stream.replace("hub-catalogs",
            partial: "admin/clients/hub_catalogs",
            locals: { client: @client, catalogs: catalogs })
        end
        format.html { redirect_to admin_client_path(@client), notice: "Catalog products updated." }
      end
    rescue ActiveRecord::RecordInvalid
      redirect_to admin_client_path(@client), alert: "Failed to update catalog products."
    end

    private

    def set_client
      @client = Client.find(params[:client_id])
    end

    def set_catalog
      @catalog = @client.catalogs.find(params[:catalog_id])
    end
  end
end
