class Checkouts::ItemsController < BaseController
  before_action :set_checkout
  before_action :set_item, only: [ :update, :destroy ]

  def create
    inventory = current_client.inventories.find(params[:id])
    quantity = [ params[:quantity].to_i, 1 ].max

    existing = @checkout.checkout_items.find_by(client_inventory_id: inventory.id)
    if existing
      existing.increment!(:quantity, quantity)
    else
      @checkout.checkout_items.create!(client_inventory_id: inventory.id, quantity: quantity)
    end

    @checkout.reload
    @checkout_basket_count = nil
    respond_to do |format|
      format.turbo_stream
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def update
    new_quantity = params[:quantity].to_i
    if new_quantity <= 0
      @item.destroy!
    else
      @item.update!(quantity: new_quantity)
    end
    @checkout.reload
    @checkout_basket_count = nil
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: new_inventory_checkout_path }
    end
  end

  def destroy
    @item.destroy!
    @checkout.reload
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: new_inventory_checkout_path }
    end
  end

  def clear
    @checkout.checkout_items.destroy_all
    @checkout.reload
    @checkout_basket_count = nil
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: new_inventory_checkout_path }
    end
  end

  def batch
    ids = Array(params[:inventory_ids]).compact_blank
    quantities = params.permit(quantities: {})[:quantities].to_h
    current_client.inventories.where(id: ids).find_each do |inventory|
      qty = [ quantities[inventory.id.to_s].to_i, 1 ].max
      existing = @checkout.checkout_items.find_by(client_inventory_id: inventory.id)
      if existing
        existing.increment!(:quantity, qty)
      else
        @checkout.checkout_items.create!(client_inventory_id: inventory.id, quantity: qty)
      end
    rescue ActiveRecord::RecordInvalid
      next
    end
    @checkout.reload
    @checkout_basket_count = nil
    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_checkout
    @checkout = current_client.checkouts.find_or_create_by!(status: :draft, user: current_user)
  end

  def set_item
    @item = @checkout.checkout_items.find_by!(client_inventory_id: params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.turbo_stream { render :error, status: :not_found }
    end
  end
end
