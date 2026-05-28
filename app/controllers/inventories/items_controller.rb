class Inventories::ItemsController < BaseController
  before_action :set_checkout
  before_action :set_item, only: [ :update, :destroy ]

  def create
    inventory = current_client.inventories.find(params[:client_inventory_id])
    quantity = [params[:quantity].to_i, 1].max

    existing = @checkout.checkout_items.find_by(client_inventory_id: inventory.id)
    if existing
      existing.increment!(:quantity, quantity)
    else
      @checkout.checkout_items.create!(client_inventory_id: inventory.id, quantity: quantity)
    end

    @checkout.reload
    respond_to do |format|
      format.turbo_stream
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.turbo_stream { render :error, status: :not_found }
    end
  end

  def update
    new_quantity = params[:quantity].to_i
    if new_quantity <= 0
      @item.destroy!
    else
      @item.update!(quantity: new_quantity)
    end
    @checkout.reload
    respond_to do |format|
      format.turbo_stream
    end
  end

  def destroy
    @item.destroy!
    @checkout.reload
    respond_to do |format|
      format.turbo_stream
    end
  end

  def clear
    @checkout.checkout_items.destroy_all
    @checkout.reload
    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_checkout
    @checkout = current_client.checkouts.find_by!(
      id: params[:checkout_id],
      status: :draft,
      user: current_user
    )
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.turbo_stream { render :error, status: :not_found }
    end
  end

  def set_item
    @item = @checkout.checkout_items.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.turbo_stream { render :error, status: :not_found }
    end
  end
end
