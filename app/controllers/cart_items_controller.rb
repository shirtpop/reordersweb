class CartItemsController < BaseController
  def create
    catalog = current_client.catalogs.active.find(params[:catalog_id])
    product = catalog.products.find(params[:product_id])

    # Use service to add items to cart
    adder = CartItems::Adder.new(
      client: current_client,
      user: current_user,
      catalog: catalog,
      product: product,
      items_params: params[:items]
    )

    @cart = adder.call
    added_count = adder.items_added

    respond_to do |format|
      format.turbo_stream {
        flash.now[:notice] = "Added #{added_count} item(s) to cart!"
        @catalog_id = catalog.id
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
    @item = OrderItem.joins(:order)
                     .merge(Order.in_cart.where(client: current_client, id: params[:order_item][:order_id]))
                     .find(params[:id])
    new_quantity = params[:order_item][:quantity].to_i

    # Validate quantity
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
    # Find the order item within the current user's cart orders
    @item = current_client.orders.in_cart
                         .where(ordered_by: current_user)
                         .joins(:order_items)
                         .find_by!(order_items: { id: params[:id] })
                         .order_items.find(params[:id])

    @item.destroy!

    redirect_to cart_path, notice: "Item removed from cart"
  rescue ActiveRecord::RecordNotFound
    redirect_to cart_path, alert: "Item not found in cart"
  end
end
