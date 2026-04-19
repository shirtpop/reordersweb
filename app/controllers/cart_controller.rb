class CartController < BaseController
  def show
    carts = current_client.orders.in_cart
                          .where(ordered_by: current_user)
                          .includes(order_items: { product: :drive_files }, catalog: :client)

    @cart_data = carts.select { |cart| cart.order_items.any? }.map do |cart|
      sorted_items = cart.order_items.to_a.sort_by do |item|
        [ item.color, Product::SIZES.index(item.size) || Float::INFINITY ]
      end
      { cart: cart, sorted_items: sorted_items, calculator: Orders::Calculator.new(order: cart) }
    end
  end
end
