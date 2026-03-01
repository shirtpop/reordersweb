class OrdersController < BaseController
  before_action :set_order, only: [ :show, :received, :duplicate ]
  def index
    # Only show submitted orders (exclude cart/draft orders)
    @pagy, @orders = pagy(current_client.orders.submitted
                                       .includes(:project, order_items: :product)
                                       .order(id: :desc))
  end

  def show; end

  def create
    creator = Orders::Creator.new(order: current_client.orders.new(order_params))
    @order = creator.call!

    if creator.success?
      redirect_to @order, notice: "Order was successfully created."
    else
      redirect_to project_path(@order.project_id), alert: @order.errors.full_messages.to_sentence
    end
  end

  def received
    Orders::Receiver.call!(order: @order, user: current_user)
    redirect_to @order, notice: "Order was successfully received."

  rescue Orders::Receiver::Error => e
    redirect_to @order, alert: e.message
  end

  def duplicate
    cart = Orders::Duplicator.new(order: @order, user: current_user).call!
    redirect_to cart_path, notice: "Order items added to cart! Review and checkout when ready."
  rescue Orders::Duplicator::EmptyOrderError => e
    redirect_to @order, alert: "Cannot reorder: #{e.message}"
  rescue Orders::Duplicator::ProductNotFoundError => e
    redirect_to cart_path, alert: "Some products are no longer available but available items have been added to your cart."
  rescue Orders::Duplicator::DuplicateError => e
    redirect_to @order, alert: "Failed to duplicate order: #{e.message}"
  end

  private

  def order_params
    params.require(:order).permit(:delivery_date, :project_id, :total_price, :total_quantity,
                                  order_items_attributes: [ :id, :product_id, :quantity, :color, :size, :_destroy ])
                          .reverse_merge(ordered_by: current_user)
  end

  def set_order
    # Only allow viewing submitted orders (not cart orders)
    @order = current_client.orders.submitted.find(params[:id])
  end
end
