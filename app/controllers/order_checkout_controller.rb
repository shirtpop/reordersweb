class OrderCheckoutController < BaseController
  def show
    # Get the cart (draft order) for checkout
    @cart = current_client.orders.in_cart
                         .includes(order_items: { product: :drive_files })
                         .find_by(ordered_by: current_user)

    # Redirect if cart is empty or doesn't exist
    if @cart.nil? || @cart.order_items.empty?
      redirect_to cart_path, alert: "Your cart is empty. Please add items before checking out."
      return
    end

    # Initialize delivery date to 3 weeks from now (minimum lead time)
    @cart.delivery_date ||= Date.today + 21.days
  end

  def create
    # Get the cart
    @cart = current_client.orders.in_cart.find_by!(ordered_by: current_user)

    # Validate cart has items
    if @cart.order_items.empty?
      redirect_to cart_path, alert: "Your cart is empty."
      return
    end

    # Calculate totals using calculator service
    calculator = Orders::Calculator.new(order: @cart)

    # Update cart with delivery date and change status to pending (submitted)
    @cart.update!(
      delivery_date: checkout_params[:delivery_date],
      status: "submitted",  # Cart becomes a submitted order
      total_quantity: calculator.total_quantity,
      price: calculator.total_price
    )

    # Redirect to order confirmation
    redirect_to order_path(@cart), notice: "🎉 Order submitted successfully! We'll process your order and send you a confirmation email."
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = "Failed to submit order: #{e.message}"
    render :show, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound
    redirect_to cart_path, alert: "Cart not found. Please try again."
  end

  private

  def checkout_params
    params.require(:order).permit(:delivery_date)
  end
end
