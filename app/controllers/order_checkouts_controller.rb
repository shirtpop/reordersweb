class OrderCheckoutsController < BaseController
  before_action :block_demo_checkout, only: :create

  def show
    @cart = current_user.in_cart_order

    unless @cart
      redirect_to cart_path, alert: "Cart not found. Please try again."
      return
    end

    if @cart.order_items.empty?
      redirect_to cart_path, alert: "Your cart is empty. Please add items before checking out."
      return
    end

    violations = Orders::MinimumOrderValidator.new(order_items: @cart.order_items).violations
    if violations.any?
      redirect_to cart_path, alert: violations.join(" ")
      return
    end

    @cart.delivery_date ||= Date.current + 21.days
  end

  def create
    @cart = current_user.in_cart_order

    unless @cart
      redirect_to cart_path, alert: "Cart not found. Please try again."
      return
    end

    if @cart.order_items.empty?
      redirect_to cart_path, alert: "Your cart is empty."
      return
    end

    violations = Orders::MinimumOrderValidator.new(order_items: @cart.order_items).violations
    if violations.any?
      redirect_to cart_path, alert: violations.join(" ")
      return
    end

    calculator = Orders::Calculator.new(order: @cart)

    @cart.update!(
      delivery_date: checkout_params[:delivery_date],
      notes: checkout_params[:notes],
      purchase_order: checkout_params[:purchase_order],
      status: "submitted",
      total_quantity: calculator.total_quantity,
      price: calculator.total_price
    )

    redirect_to order_path(@cart), notice: "🎉 Order submitted successfully! You’ll receive a confirmation email shortly."
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = "Failed to submit order: #{e.message}"
    render :show, status: :unprocessable_entity
  end

  private

  def block_demo_checkout
    return unless current_client.demo?

    redirect_to cart_path, alert: "This is a trial account — checkout is disabled. Contact us to place a real order."
  end

  def checkout_params
    params.require(:order).permit(:delivery_date, :notes, :purchase_order)
  end
end
