class CheckoutsController < BaseController
  before_action :require_masquerading, only: [ :destroy, :destroy_movement ]

  def index
    checkouts = filtered_checkouts

    respond_to do |format|
      format.html { @pagy, @checkouts = pagy(checkouts, items: 20) }
      format.csv do
        exportable_checkouts = checkouts.includes(
          :user,
          inventory_movements: { client_inventory: { client_product_variant: :client_product } }
        )
        csv = Checkouts::CsvExporter.new(exportable_checkouts).call
        send_data csv, filename: "checkouts-#{Time.current.strftime('%Y%m%d-%H%M%S')}.csv"
      end
    end
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

  # Cleanup for test/stray checkouts, only reachable by an admin masquerading as the
  # client — real clients never see these actions on their own checkout history.
  def destroy
    checkout = current_client.checkouts.confirmed.find(params[:id])
    checkout.destroy!
    redirect_to inventory_checkouts_path(format: :html), notice: "Checkout deleted."
  end

  def destroy_movement
    checkout = current_client.checkouts.confirmed.find(params[:id])
    movement = checkout.inventory_movements.find(params[:movement_id])

    ActiveRecord::Base.transaction do
      checkout.checkout_items.find_by(client_inventory_id: movement.client_inventory_id)&.destroy!
      movement.destroy!
    end

    redirect_to inventory_checkout_path(checkout), notice: "Item removed."
  end

  private

  def filtered_checkouts
    checkouts = current_client.checkouts.confirmed.order(created_at: :desc)
    checkouts = checkouts.search_by_name(params[:q]) if params[:q].present?

    if (date_from = parse_filter_date(params[:date_from]))
      checkouts = checkouts.created_from(date_from)
    end

    if (date_to = parse_filter_date(params[:date_to]))
      checkouts = checkouts.created_to(date_to)
    end

    checkouts
  end

  def parse_filter_date(value)
    Date.parse(value) if value.present?
  rescue ArgumentError
    nil
  end

  def require_masquerading
    redirect_to inventory_checkouts_path, alert: "Not authorized." unless Current.masquerading
  end

  def checkout_params
    params.require(:client_checkout).permit(
      :purpose,
      :recipient_first_name,
      :recipient_last_name
    )
  end
end
