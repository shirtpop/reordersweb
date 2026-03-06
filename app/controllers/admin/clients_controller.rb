module Admin
  class ClientsController < BaseController
    before_action :set_client, only: [ :edit, :show, :update, :destroy ]

    def index
      scope = params[:q].present? ? Client.search_by_name(params[:q]) : Client.order(created_at: :desc)
      @pagy, @clients = pagy(scope)
    end

    def show
      @assigned_products = @client.assigned_products
      @catalogs = @client.catalogs.includes(:products).order(created_at: :desc)
      @recent_orders = @client.orders.includes(:catalog).order(created_at: :desc).limit(10)
      @recent_client_products = @client.client_products.order(created_at: :desc).limit(5)
    end

    def new
      @client = Client.new
      @client.build_address
      @client.build_shipping_address
      @client.users.build
    end

    def new_wizard
      @client = Client.new
      @client.build_address
      @client.build_shipping_address
    end

    def create
      creator = Clients::Creator.new(
        client_params:,
        same_as_main: params[:same_as_main] == "1" || params[:same_as_main] == "true",
        catalog_name: params[:catalog_name],
        catalog_status: params[:catalog_status],
        product_ids: params[:product_ids]
      )
      @client = creator.call!

      if creator.success?
        redirect_to admin_client_path(@client), notice: "Client was successfully created."
      else
        if params[:catalog_name].present?
          render :new_wizard
        else
          render :new
        end
      end
    end

    def edit; end

    def update
      updater = Clients::Updater.new(
        client: @client,
        client_params: client_params,
        same_as_main: params[:same_as_main] == "1" || params[:same_as_main] == "true"
      )

      @client = updater.call

      unless updater.failed?
        redirect_to admin_clients_path, notice: "Client was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      Clients::Destroyer.new(client: @client).call!
      redirect_to admin_clients_path, notice: "Client was successfully deleted."
    rescue Clients::Destroyer::DeleteError => e
      redirect_to admin_clients_path, alert: e.message
    end

    private

    def set_client
      @client = Client.includes(:address, :shipping_address, :users).find(params[:id])
    end

    def client_params
      params.require(:client).permit(
        :company_name,
        :personal_name,
        :phone_number,
        :same_as_main,
        :company_url,
        :inventory_enabled,
        address_attributes: [ :id, :street, :city, :state, :zip_code ],
        shipping_address_attributes: [ :id, :street, :city, :state, :zip_code ],
        users_attributes: [ :id, :email, :password, :role, :client_id ]
      )
    end

    def client_only_params
      client_params.slice(:company_name, :personal_name, :phone_number)
    end

    def main_address_params
      client_params[:address_attributes] || {}
    end

    def shipping_address_params
      client_params[:shipping_address_attributes] || {}
    end

    def user_params
      client_params[:users_attributes].values.first || {}
    end
  end
end
