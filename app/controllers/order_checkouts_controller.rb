class OrderCheckoutsController < BaseController
  def show
    @cart = cart_order_scope
              .includes(order_items: { product: :drive_files })
              .find(params[:order_id])

    if @cart.order_items.empty?
      redirect_to cart_path, alert: "Your cart is empty. Please add items before checking out."
      return
    end

    @cart.delivery_date ||= Date.current + 21.days
  rescue ActiveRecord::RecordNotFound
    redirect_to cart_path, alert: "Cart not found. Please try again."
  end

  def create
    @cart = cart_order_scope.find(params[:order_id])

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

  def cart_order_scope
    current_client.orders.in_cart.where(ordered_by: current_user)
  end

  def checkout_params
    params.require(:order).permit(:delivery_date)
  end
end
