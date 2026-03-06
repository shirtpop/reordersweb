class CartController < BaseController
  def show
    # Get all cart orders for the current user (there may be multiple, one per catalog)
    @carts = current_client.orders.in_cart
                          .where(ordered_by: current_user)
                          .includes(order_items: { product: :drive_files }, catalog: :client)

    # For now, we'll work with a single cart (first one) or create empty
    # In the future, we could support multiple carts from different catalogs
    @cart = @carts.first || current_client.orders.new(status: "cart", ordered_by: current_user)

    # Sort order items by color (alphabetically) and size (by Product::SIZES order)
    unless @cart.new_record?
      @sorted_items = @cart.order_items.to_a.sort_by do |item|
        [
          item.color,
          Product::SIZES.index(item.size) || Float::INFINITY
        ]
      end
    end

    # Initialize calculator for price calculations with bulk pricing
    @calculator = Orders::Calculator.new(order: @cart) unless @cart.new_record?
  end
end
