module Admin
  class ClientsController < BaseController
    before_action :set_client, only: [:edit, :show,:update, :destroy]

    def index
      @clients = if params[:q].present?
               Client.search_by_name(params[:q])
             else
               Client.order(created_at: :desc)
             end

      respond_to do |format|
        format.html
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "clients_table",
            partial: "table",
            locals: { clients: @clients }
          )
        end
        format.json do
          render json: {
            clients: @clients.map do |client|
              {
                id: client.id,
                company_name: client.company_name,
                personal_name: client.personal_name
              }
            end
          }
        end
      end
    end

    def show; end

    def new
      @client = Client.new
      @client.build_address
      @client.build_shipping_address
      @client.users.build
    end

    def create
      creator = Clients::Creator.new(client_params:, same_as_main: params[:same_as_main] == '1' || params[:same_as_main] == 'true')
      @client = creator.call!

      if creator.success?
        redirect_to admin_clients_path, notice: "Client was successfully created."
      else
        render :new
      end
    end
          
    def edit; end

    def update
      updater = Clients::Updater.new(
        client: @client,
        client_params: client_params,
        same_as_main: params[:same_as_main] == '1' || params[:same_as_main] == 'true'
      )

      @client = updater.call

      unless updater.failed?
        redirect_to admin_clients_path, notice: "Client was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      @client.destroy
      respond_to do |format|
        format.html { 
          redirect_to admin_clients_path, 
          notice: 'Client was successfully deleted.' 
        }
        format.json { 
          render json: { 
            status: 'success', 
            message: 'Client deleted successfully' 
          }
        }
      end
    end

    private

    def set_client
      @client = Client.find(params[:id])
    end

    def client_params
      params.require(:client).permit(
        :company_name, 
        :personal_name, 
        :phone_number,
        :same_as_main,
        address_attributes: [:id, :street, :city, :state, :zip_code],
        shipping_address_attributes: [:id, :street, :city, :state, :zip_code],
        users_attributes: [:id, :email, :password, :role, :client_id]
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