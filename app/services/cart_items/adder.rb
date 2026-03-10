module CartItems
  class Adder
    attr_reader :cart, :items_added

    def initialize(client:, user:, catalog:, product:, items_params:)
      @client = client
      @user = user
      @catalog = catalog
      @product = product
      @items_params = items_params
      @items_added = 0
    end

    def call
      ActiveRecord::Base.transaction do
        find_or_create_cart
        add_items_to_cart
        @cart.save!
      end

      @cart
    end

    private

    def find_or_create_cart
      @cart = @client.orders.in_cart.find_or_initialize_by(
        catalog_id: @catalog.id,
        ordered_by: @user
      )
      # Reload order_items for existing carts to ensure we have the latest data
      @cart.order_items.reload if @cart.persisted?
    end

    def add_items_to_cart
      return unless @items_params.present?

      @items_params.each do |_key, item_params|
        # Handle both string and symbol keys
        quantity = item_params[:quantity].to_i
        next if quantity <= 0

        add_or_update_item(item_params, quantity)
      end
    end

    def add_or_update_item(item_params, quantity)
      color = item_params[:color]
      size = item_params[:size]

      # Find existing item in the cart's order_items collection
      existing_item = find_existing_item(color, size)

      if existing_item
        # Update existing item
        existing_item.quantity += quantity
        existing_item.save!
      else
        # Build new item
        @cart.order_items.build(
          product_id: @product.id,
          color: color,
          size: size,
          quantity: quantity
        )
      end

      @items_added += 1
    end

    def find_existing_item(color, size)
      @cart.order_items.find do |item|
        item.product_id == @product.id &&
          item.color == color &&
          item.size == size
      end
    end
  end
end
