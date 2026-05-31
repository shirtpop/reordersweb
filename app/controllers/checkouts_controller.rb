class CheckoutsController < BaseController
  def index
    checkouts = current_client.checkouts.confirmed.order(created_at: :desc)
    checkouts = checkouts.search_by_name(params[:q]) if params[:q].present?

    @pagy, @checkouts = pagy(checkouts, items: 20)
  end

  def show
    @checkout = current_client.checkouts.confirmed.find(params[:id])
  end

  def new
    @checkout = current_client.checkouts.find_or_initialize_by(status: :draft, user: current_user)
    @checkout.save! unless @checkout.persisted?
    @has_draft_items = @checkout.checkout_items.any?
  end

  def create
    @checkout = current_client.checkouts.find_by!(status: :draft, user: current_user)
    @checkout.assign_attributes(checkout_params)

    creator = Checkouts::Creator.new(user: current_user, checkout: @checkout)
    creator.call!

    redirect_to inventory_checkouts_path, notice: "Checkout created successfully."

  rescue ActiveRecord::RecordNotFound
    redirect_to new_inventory_checkout_path, alert: "No active draft found. Please add items first."
  rescue Checkouts::Creator::Error => e
    @checkout ||= current_client.checkouts.find_or_initialize_by(status: :draft, user: current_user)
    @has_draft_items = @checkout.checkout_items.any?
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  private

  def checkout_params
    params.require(:client_checkout).permit(
      :recipient_email,
      :recipient_first_name,
      :recipient_last_name
    )
  end
end
