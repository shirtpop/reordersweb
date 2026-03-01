module Orders
  class Duplicator
    class DuplicateError < StandardError; end
    class ProductNotFoundError < DuplicateError; end
    class EmptyOrderError < DuplicateError; end

    def initialize(order:, user:)
      @original_order = order
      @user = user
      @client = order.client
    end

    def call!
      validate_has_items!
      cart = find_or_create_cart
      available_products = validate_products

      ActiveRecord::Base.transaction do
        duplicate_order_items(cart, available_products)
        cart.save!
      end

      cart
    end

    private

    def validate_has_items!
      raise EmptyOrderError, "Original order has no items" if @original_order.order_items.empty?
    end

    def find_or_create_cart
      @client.orders.in_cart.find_or_initialize_by(
        project_id: @original_order.project_id,
        ordered_by: @user
      )
    end

    def validate_products
      product_ids = @original_order.order_items.pluck(:product_id).uniq
      products = Product.where(id: product_ids).index_by(&:id)

      missing_count = product_ids.size - products.size
      if missing_count == product_ids.size
        raise EmptyOrderError, "All products from this order are no longer available"
      elsif missing_count > 0
        raise ProductNotFoundError, "#{missing_count} product(s) no longer available"
      end

      products
    end

    def duplicate_order_items(cart, available_products)
      @original_order.order_items.each do |item|
        next unless available_products[item.product_id]

        cart.order_items.build(
          product_id: item.product_id,
          color: item.color,
          size: item.size,
          quantity: item.quantity
        )
      end
    end
  end
end
