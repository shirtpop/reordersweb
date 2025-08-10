module Clients
  class Updater
    def initialize(client:, client_params:, same_as_main:)
      @client = client
      @main_address_params = client_params[:address_attributes]
      @shipping_address_params = client_params[:shipping_address_attributes]
      @same_as_main = same_as_main
      @failed = false
    end

    def call
      ActiveRecord::Base.transaction do
        main_address = replace_address_if_changed(@client.address, @main_address_params)

        shipping_address =
          if @same_as_main
            main_address
          else
            replace_address_if_changed(@client.shipping_address, @shipping_address_params)
          end

        @client.update!(
          @client_params.merge(
            address: main_address,
            shipping_address: shipping_address
          )
        )
      end
      @client

    rescue ActiveRecord::RecordInvalid => e
      @failed = true
      @client
    end

    def failed?
      @failed
    end

    private

    def replace_address_if_changed(current_address, new_params)
      if address_changed?(current_address, new_params)
        Address.create!(new_params)
      else
        current_address
      end
    end

    def address_changed?(address, params)
      params.any? { |key, value| address.send(key) != value }
    end
  end
end
