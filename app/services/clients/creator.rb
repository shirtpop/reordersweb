module Clients
  class Creator
    attr_reader :client

    def initialize(client_params:, same_as_main:)
      @main_address_params = client_params[:address_attributes]
      @shipping_address_params = client_params[:shipping_address_attributes]
      @user_params = client_params[:users_attributes]
      @same_as_main = same_as_main
      @client = Client.new(client_params.slice(:company_name, :personal_name, :phone_number))
      @failed = false
    end

    def call!
      ActiveRecord::Base.transaction do
        billing_address = create_address!(@main_address_params)
        shipping_address = @same_as_main ? billing_address : create_address!(@shipping_address_params)

        @client.assign_attributes(address: billing_address, shipping_address: shipping_address)
        @client.save!
        create_users! if @user_params.present?
      end

      @client
    rescue ActiveRecord::RecordInvalid
      @failed = true
      @client
    end

    def success?
      @client.persisted? && !@failed
    end

    private

    def create_address!(params)
      Address.create!(params)
    end

    def create_users!
      @user_params.values.each do |user_param|
        user = @client.users.create!(user_param.merge(client_id: @client.id))
        UserMailer.with(user_id: user.id, password: user_param[:password]).welcome_client.deliver_later
      end
    end
  end
end
