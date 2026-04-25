module Admin
  class OrdersController < BaseController
    def index
      scope = params[:q].present? ? Order.search_by_keyword(params[:q]) : Order.order(created_at: :desc)
      @pagy, @orders = pagy(scope.includes(:client, :catalog))
    end

    def show
      @order = Order.find(params[:id])
    end

    def update
      @order = Order.find(params[:id])
      if @order.update(order_params)
        redirect_to admin_order_path(@order), notice: "Order updated."
      else
        redirect_to admin_order_path(@order), alert: "Failed to update order."
      end
    end

    def mark_as_processing
      @order = Order.find(params[:id])
      @order.status_processing!
      redirect_to admin_order_path(@order), notice: "Order marked as processing."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_order_path(@order), alert: "Failed to update order: #{e.message}"
    end

    private

    def order_params
      params.require(:order).permit(:invoice_url)
    end
  end
end
