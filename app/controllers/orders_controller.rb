class OrdersController < ApplicationController
  def index
    @orders = current_client.orders.includes(:project, order_items: :product)
  end

  def show
    @order = current_client.orders.find(params[:id])
  end

  def create
    creator = Orders::Creator.new(order: current_client.orders.new(order_params))
    @order = creator.call!

    if creator.success?
      redirect_to @order, notice: 'Order was successfully created.'
    else
      redirect_to project_path(@order.project_id), alert: @order.errors.full_messages.to_sentence
    end
  end

  private

  def order_params
    params.require(:order).permit(:delivery_date, :project_id, :total_price, :total_quantity,
                                  order_items_attributes: [:id, :product_id, :quantity, :color, :size, :_destroy])
  end
end
