module Admin
  class OrdersController < BaseController
    def index
      scope = params[:q].present? ? Order.search_by_keyword(params[:q]) : Order.order(created_at: :desc)
      @pagy, @orders = pagy(scope.includes(:client, :catalog))
    end

    def show
      @order = Order.find(params[:id])
      @inventory_movements_count = Client::InventoryMovement.where(order_item_id: @order.order_item_ids).count
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

    def cancel
      @order = Order.find(params[:id])
      @order.status_cancelled!
      redirect_to admin_order_path(@order), notice: "Order cancelled."
    rescue ActiveRecord::RecordInvalid => e
      redirect_to admin_order_path(@order), alert: "Failed to cancel order: #{e.message}"
    end

    def destroy
      @order = Order.find(params[:id])
      @order.destroy
      redirect_to admin_orders_path(format: :html), notice: "Order deleted."
    end

    private

    def order_params
      params.require(:order).permit(:invoice_url)
    end
  end
end
