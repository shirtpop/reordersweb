module Admin
  class OrdersController < BaseController
    def index
      scope = params[:q].present? ? Order.search_by_keyword(params[:q]) : Order.order(created_at: :desc)
      @pagy, @orders = pagy(scope.includes(:client, :catalog))
    end

    def show
      @order = Order.find(params[:id])
    end
  end
end
