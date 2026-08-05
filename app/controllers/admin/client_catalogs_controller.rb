module Admin
  class ClientCatalogsController < BaseController
    before_action :set_client
    before_action :set_catalog, only: [ :update, :destroy, :move_up, :move_down ]

    def create
      @catalog = @client.catalogs.new(catalog_params)
      @catalog.order = @client.catalogs.maximum(:order).to_i + 1

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

    def move_up
      swap_order(-1)
    end

    def move_down
      swap_order(1)
    end

    private

    def swap_order(direction)
      siblings = @client.catalogs.ordered.to_a
      index = siblings.index(@catalog)
      sibling = siblings[index + direction] if index && (index + direction).between?(0, siblings.size - 1)

      if sibling
        Catalog.transaction do
          original_order = @catalog.order
          @catalog.update!(order: sibling.order)
          sibling.update!(order: original_order)
        end
      end

      respond_to do |format|
        format.turbo_stream { render_catalogs_stream }
        format.html { redirect_to admin_client_path(@client) }
      end
    end

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
      catalogs = @client.catalogs.includes(products: :product_colors).ordered
      render turbo_stream: turbo_stream.replace("hub-catalogs",
        partial: "admin/clients/hub_catalogs",
        locals: { client: @client, catalogs: catalogs })
    end
  end
end
