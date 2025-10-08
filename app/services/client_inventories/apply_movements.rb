# app/services/client_inventories/apply_movements.rb
module ClientInventories
  class ApplyMovements
    def self.call!(user:, movements_params:)
      new(user:, movements_params:).call!
    end

    attr_reader :user, :movements_params

    def initialize(user:, movements_params:)
      @user = user
      @movements_params = movements_params
    end

    def call!
      ActiveRecord::Base.transaction do
        product_variants.each { |variant_params| apply_to_variant!(variant_params) }
      end
    end

    private

    def client_id
      @client_id ||= user.client_id
    end

    def product_variants
      @product_variants ||= movements_params[:product_variants] || []
    end

    def movement_type
      @movement_type ||= movements_params[:movement_type].to_sym
    end

    def find_or_create_inventory!(variant_id)
      Client::Inventory.find_or_create_by!(
        client_id: client_id,
        client_product_variant_id: variant_id
      )
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    def apply_to_variant!(variant_params)
      variant_id = variant_params[:product_variant_id]
      quantity = variant_params[:product_variant_quantity].to_i

      inventory = find_or_create_inventory!(variant_id)

      inventory.inventory_movements.create!(
        user_id: user.id,
        movement_type: movement_type.to_s,
        quantity: quantity
      )

      if Client::InventoryMovement::INCREASE_MOVEMENTS.include?(movement_type)
        inventory.increment!(:quantity, quantity)
      elsif Client::InventoryMovement::DECREASE_MOVEMENTS.include?(movement_type)
        inventory.decrement!(:quantity, quantity)
      else
        raise ArgumentError, "Unknown movement type: #{movement_type}"
      end
    end
  end
end
