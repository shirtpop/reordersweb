class CartController < BaseController
  def show
    @cart = current_user.in_cart_order

    if @cart&.order_items&.any?
      @sorted_items = @cart.order_items.to_a.sort_by do |item|
        [ item.color, Product::SIZES.index(item.size) || Float::INFINITY ]
      end
      @calculator = Orders::Calculator.new(order: @cart)
    else
      @sorted_items = []
    end
  end
end
