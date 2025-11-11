class CheckoutsController < BaseController
  def index
    checkouts = current_client.checkouts.order(created_at: :desc)
    checkouts = checkouts.search_by_name(params[:q]) if params[:q].present?

    @pagy, @checkouts = pagy(checkouts, items: 20)
  end

  def show
    @checkout = current_client.checkouts.find(params[:id])
  end

  def new
    @checkout = current_client.checkouts.new
  end

  def create
    creator = Checkouts::Creator.new(user: current_user, checkout: current_client.checkouts.new(checkout_params))
    creator.call!

    redirect_to checkouts_path, notice: "Checkout created successfully."

  rescue Checkouts::Creator::Error => e
    @checkout = creator.checkout
    render :new
  end

  private

  def checkout_params
    params.require(:client_checkout).permit(
      :recipient_email,
      :recipient_first_name,
      :recipient_last_name,
      inventory_movements_attributes: [
        :client_inventory_id,
        :quantity,
        :movement_type
      ]
    )
  end
end
