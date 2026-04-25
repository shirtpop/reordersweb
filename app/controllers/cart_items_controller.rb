class CartItemsController < BaseController
  def create
    product = Product.joins(:catalogs)
                     .merge(Catalog.active.where(id: params[:catalog_id], client_id: current_client.id))
                     .find(params[:product_id])

    # Use service to add items to cart
    adder = CartItems::Adder.new(
      client: current_client,
      user: current_user,
      product: product,
      items_params: params[:items]
    )

    @cart = adder.call
    added_count = adder.items_added

    respond_to do |format|
      format.turbo_stream {
        flash.now[:notice] = "Added #{added_count} item(s) to cart!"
        @catalog_id = params[:catalog_id]
        @item_count = added_count
      }
      format.json {
        render json: {
          success: true,
          message: "Added #{added_count} item(s) to cart",
          cart_count: @cart.order_items.sum(:quantity)
        }
      }
      format.html {
        redirect_to cart_path, notice: "Added #{added_count} item(s) to cart!"
      }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.turbo_stream {
        flash.now[:alert] = "Product or catalog not found"
        render :error, status: :not_found
      }
      format.json { render json: { success: false, message: "Product or catalog not found" }, status: :not_found }
      format.html { redirect_to storefront_path, alert: "Product or catalog not found" }
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.turbo_stream {
        flash.now[:alert] = "Failed to add items to cart: #{e.message}"
        render :error, status: :unprocessable_entity
      }
      format.json { render json: { success: false, message: e.message }, status: :unprocessable_entity }
      format.html { redirect_to storefront_path, alert: "Failed to add items to cart: #{e.message}" }
    end
  end

  def update
    @item = current_user.in_cart_order.order_items.find(params[:id])
    new_quantity = params[:order_item][:quantity].to_i

    violations = minimum_order_violations_for_update(@item, new_quantity)

    if violations.any?
      respond_to do |format|
        format.turbo_stream {
          flash.now[:alert] = violations.join(" ")
          @cart = @item.order.reload
          @calculator = Orders::Calculator.new(order: @cart)
          render :update
        }
        format.html { redirect_to cart_path, alert: violations.join(" ") }
      end
      return
    end

    if new_quantity <= 0
      @item.destroy!
      message = "Item removed from cart"
    else
      @item.update!(quantity: new_quantity)
      message = "Quantity updated"
    end

    respond_to do |format|
      format.turbo_stream {
        flash.now[:notice] = message
        @cart = @item.order.reload  # Reload to get updated order_items
        @calculator = Orders::Calculator.new(order: @cart)
        render :update
      }
      format.html {
        redirect_to cart_path, notice: message
      }
    end
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.turbo_stream {
        flash.now[:alert] = "Item not found in cart"
        render :error, status: :not_found
      }
      format.html { redirect_to cart_path, alert: "Item not found in cart" }
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.turbo_stream {
        flash.now[:alert] = "Failed to update quantity: #{e.message}"
        render :error, status: :unprocessable_entity
      }
      format.html { redirect_to cart_path, alert: "Failed to update quantity: #{e.message}" }
    end
  end

  def destroy
    cart = current_user.in_cart_order
    raise ActiveRecord::RecordNotFound unless cart

    items = cart.order_items.where(product_id: params[:id])
    raise ActiveRecord::RecordNotFound if items.empty?

    items.destroy_all

    redirect_to cart_path, notice: "Product removed from cart"
  rescue ActiveRecord::RecordNotFound
    redirect_to cart_path, alert: "Item not found in cart"
  end

  private

  def minimum_order_violations_for_update(item, new_quantity)
    simulated_items = current_user.in_cart_order.order_items.where(product_id: item.product_id).map do |oi|
                            qty = oi.id == item.id ? new_quantity : oi.quantity
                            Orders::MinimumOrderValidator::Item.new(item.product, oi.color, qty)
                          end

    Orders::MinimumOrderValidator.new(order_items: simulated_items).violations
  end
end
