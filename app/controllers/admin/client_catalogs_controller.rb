module Admin
  class ClientCatalogsController < BaseController
    before_action :set_client
    before_action :set_catalog, only: [ :update, :destroy ]

    def create
      @catalog = @client.catalogs.new(catalog_params)

      if @catalog.save
        respond_to do |format|
          format.turbo_stream { render_catalogs_stream }
          format.html { redirect_to admin_client_path(@client), notice: "Catalog created successfully." }
        end
      else
        redirect_to admin_client_path(@client), alert: @catalog.errors.full_messages.join(", ")
      end
    end

    def update
      update_params = {}
      update_params[:status] = params[:status] if params[:status].present?
      update_params[:name] = params.dig(:catalog, :name) if params.dig(:catalog, :name).present?

      if @catalog.update(update_params)
        respond_to do |format|
          format.turbo_stream { render_catalogs_stream }
          format.html { redirect_to admin_client_path(@client), notice: "Catalog updated successfully." }
        end
      else
        redirect_to admin_client_path(@client), alert: @catalog.errors.full_messages.join(", ")
      end
    end

    def destroy
      @catalog.destroy
      respond_to do |format|
        format.turbo_stream { render_catalogs_stream }
        format.html { redirect_to admin_client_path(@client), notice: "Catalog deleted successfully." }
      end
    end

    private

    def set_client
      @client = Client.find(params[:client_id])
    end

    def set_catalog
      @catalog = @client.catalogs.find(params[:id])
    end

    def catalog_params
      params.require(:catalog).permit(:name, :status)
    end

    def render_catalogs_stream
      catalogs = @client.catalogs.includes(:products).order(created_at: :desc)
      render turbo_stream: turbo_stream.replace("hub-catalogs",
        partial: "admin/clients/hub_catalogs",
        locals: { client: @client, catalogs: catalogs })
    end
  end
end
