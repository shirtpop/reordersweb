module ClientInventories
  class AddCatalogProduct
    class NotAssignedError < StandardError; end
    class AlreadyAddedError < StandardError; end
    class NoQuantityError < StandardError; end

    def self.call!(client:, user:, product_id:, variants_params:)
      new(client:, user:, product_id:, variants_params:).call!
    end

    def initialize(client:, user:, product_id:, variants_params:)
      @client = client
      @user = user
      @product_id = product_id
      @variants_params = variants_params
    end

    def call!
      raise NotAssignedError, "Product is not assigned to this client" unless assigned_product
      raise NoQuantityError, "Enter a quantity for at least one size and color" if valid_variants.empty?

      ActiveRecord::Base.transaction do
        client_product = create_client_product!
        valid_variants.each { |variant_params| add_variant!(client_product, variant_params) }
        client_product
      end
    end

    private

    attr_reader :client, :user, :product_id, :variants_params

    def assigned_product
      @assigned_product ||= client.assigned_products.find_by(id: product_id)
    end

    def available_colors
      @available_colors ||= assigned_product.product_colors.pluck(:name)
    end

    def available_sizes
      @available_sizes ||= assigned_product.sizes
    end

    def valid_variants
      @valid_variants ||= variants_params.values.select do |variant_params|
        variant_params[:quantity].to_i.positive? &&
          available_colors.include?(variant_params[:color]) &&
          available_sizes.include?(variant_params[:size])
      end
    end

    def create_client_product!
      client.client_products.create!(product_id: product_id, name: assigned_product.name)
    rescue ActiveRecord::RecordInvalid => e
      raise AlreadyAddedError, "Product has already been added to this client's inventory" if e.record.errors[:product_id].present?

      raise
    rescue ActiveRecord::RecordNotUnique
      raise AlreadyAddedError, "Product has already been added to this client's inventory"
    end

    def add_variant!(client_product, variant_params)
      variant = client_product.product_variants.create!(
        color: variant_params[:color],
        size: variant_params[:size]
      )
      inventory = Client::Inventory.create!(client: client, client_product_variant: variant)
      inventory.inventory_movements.create!(user: user, movement_type: :add, quantity: variant_params[:quantity].to_i)
    end
  end
end
