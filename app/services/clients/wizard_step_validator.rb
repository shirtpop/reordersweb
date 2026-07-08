module Clients
  class WizardStepValidator
    def initialize(step:, params:)
      @step = step
      @params = params
    end

    def errors
      case @step
      when 1 then step_1_errors
      when 2 then step_2_errors
      when 3 then step_3_errors
      else {}
      end
    end

    private

    def step_1_errors
      errors = {}

      client = Client.new(
        company_name: @params.dig(:client, :company_name),
        personal_name: @params.dig(:client, :personal_name),
        phone_number: @params.dig(:client, :phone_number)
      )
      client.valid?
      %i[company_name personal_name phone_number].each do |field|
        errors[field] = client.errors[field] if client.errors[field].any?
      end

      addr = @params.dig(:client, :address_attributes) || {}
      billing = Address.new(street: addr[:street], city: addr[:city], state: addr[:state], zip_code: addr[:zip_code])
      unless billing.valid?
        billing.errors.each { |e| errors["billing_#{e.attribute}"] = [ e.message ] }
      end

      unless @params[:same_as_main].in?(%w[1 true])
        ship = @params.dig(:client, :shipping_address_attributes) || {}
        shipping = Address.new(street: ship[:street], city: ship[:city], state: ship[:state], zip_code: ship[:zip_code])
        unless shipping.valid?
          shipping.errors.each { |e| errors["shipping_#{e.attribute}"] = [ e.message ] }
        end
      end

      errors
    end

    def step_2_errors
      errors = {}
      rows = (@params.dig(:client, :users_attributes) || {}).values
      emails = rows.map { |row| row[:email].to_s.strip }.reject(&:blank?)

      if emails.empty?
        errors[:email] = [ "can't be blank" ]
        return errors
      end

      emails.each_with_index do |email, index|
        label = "email_#{index + 1}"

        if !URI::MailTo::EMAIL_REGEXP.match?(email)
          errors[label] = [ "is not a valid email address" ]
        elsif emails.count(email) > 1
          errors[label] = [ "is listed more than once" ]
        elsif User.exists?(email: email)
          errors[label] = [ "has already been taken" ]
        end
      end

      errors
    end

    def step_3_errors
      errors = {}
      errors[:catalog_name] = [ "can't be blank" ] if @params[:catalog_name].blank?
      errors
    end
  end
end
