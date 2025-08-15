module Admin
  class OrdersController < BaseController
    def index
      @orders = if params[:q].present?
                    Order.includes(:client, :project).search_by_keyword(params[:q])
                  else
                    Order.includes(:client, :project).order(created_at: :desc)
                  end

      respond_to do |format|
        format.html
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "orders_table",
            partial: "table",
            locals: { orders: @orders }
          )
        end
      end
    end

    def show
      @order = Order.find(params[:id])
    end
  end
end
