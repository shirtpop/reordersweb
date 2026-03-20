require 'rails_helper'

RSpec.describe CartItems::Adder do
  let(:client) { create(:client) }
  let(:user) { create(:user) }
  let(:product) { create(:product) }
  let(:catalog) do
    create(:catalog, client: client, status: 'active').tap do |proj|
      create(:catalogs_product, catalog: proj, product: product)
    end
  end
  let(:product_color) { product.colors.first['name'] }
  let(:product_size) { product.sizes.first }
  let(:product_size_last) { product.sizes.last }

  let(:items_params) do
    ActionController::Parameters.new(
      {
        "0" => { "color" => product_color, "size" => product_size, "quantity" => "2" },
        "1" => { "color" => product_color, "size" => product_size_last, "quantity" => "3" }
      }
    )
  end

  let(:service) do
    described_class.new(
      client: client,
      user: user,
      catalog: catalog,
      product: product,
      items_params: items_params
    )
  end

  describe '#call' do
    context 'when cart does not exist' do
      it 'creates a new cart' do
        expect {
          service.call
        }.to change { client.orders.in_cart.count }.by(1)
      end

      it 'associates cart with the catalog' do
        cart = service.call
        expect(cart.catalog).to eq(catalog)
      end

      it 'associates cart with the user' do
        cart = service.call
        expect(cart.ordered_by).to eq(user)
      end

      it 'sets cart status to cart' do
        cart = service.call
        expect(cart.status).to eq('cart')
      end
    end

    context 'when cart already exists' do
      let!(:existing_cart) do
        create(:order, :with_catalog_line_items,
          client: client,
          catalog: catalog,
          ordered_by: user,
          status: 'cart'
        )
      end

      it 'does not create a new cart' do
        expect {
          service.call
        }.not_to change { client.orders.in_cart.count }
      end

      it 'uses the existing cart' do
        cart = service.call
        expect(cart.id).to eq(existing_cart.id)
      end
    end

    context 'adding items' do
      it 'adds items to the cart' do
        cart = service.call
        expect(cart.order_items.count).to eq(2)
      end

      it 'creates items with correct attributes' do
        cart = service.call

        item1 = cart.order_items.find_by(color: product_color, size: product_size)
        expect(item1).to be_present
        expect(item1.product).to eq(product)
        expect(item1.quantity).to eq(2)

        item2 = cart.order_items.find_by(color: product_color, size: product_size_last)
        expect(item2).to be_present
        expect(item2.product).to eq(product)
        expect(item2.quantity).to eq(3)
      end

      it 'tracks the number of items added' do
        service.call
        expect(service.items_added).to eq(2)
      end

      it 'skips items with zero quantity' do
        items_params["2"] = { "color" => "Green", "size" => "S", "quantity" => "0" }

        cart = service.call
        expect(cart.order_items.count).to eq(2)
        expect(cart.order_items.find_by(color: "Green")).to be_nil
      end

      it 'skips items with negative quantity' do
        items_params["2"] = { "color" => "Green", "size" => "S", "quantity" => "-1" }

        cart = service.call
        expect(cart.order_items.count).to eq(2)
        expect(cart.order_items.find_by(color: "Green")).to be_nil
      end
    end

    context 'merging existing items' do
      let!(:existing_cart) do
        create(:order,
          client: client,
          catalog: catalog,
          ordered_by: user,
          status: 'cart',
          order_items: [
            build(:order_item, product: product, color: product_color, size: product_size, quantity: 5)
          ]
        )
      end

      # Override items_params to only add the existing item
      let(:items_params_merge_only) do
        {
          "0" => { "color" => product_color, "size" => product_size, "quantity" => "2" }
        }
      end

      let(:service_merge_only) do
        described_class.new(
          client: client,
          user: user,
          catalog: catalog,
          product: product,
          items_params: items_params_merge_only
        )
      end

      it 'merges quantity for existing items instead of creating duplicates' do
        expect {
          service_merge_only.call
        }.not_to change { existing_cart.order_items.count }
      end

      it 'increments the quantity of existing item' do
        cart = service.call
        item = cart.order_items.find_by(color: product_color, size: product_size)

        expect(item.product_id).to eq(product.id)
        expect(item.quantity).to eq(7) # 5 (existing) + 2 (new)
      end

      it 'still adds new items with different color/size' do
        cart = service.call

        # Existing item merged
        red_item = cart.order_items.find_by(color: product_color, size: product_size)
        expect(red_item.quantity).to eq(7)

        # New item added
        blue_item = cart.order_items.find_by(color: product_color, size: product_size_last)
        expect(blue_item.quantity).to eq(3)
        expect(blue_item.id).not_to eq(product.id)
      end

      it 'tracks all items processed including merged ones' do
        service.call
        expect(service.items_added).to eq(2)
      end
    end

    context 'with no items params' do
      let(:items_params) { nil }

      it 'creates cart but adds no items' do
        expect {
          service.call
        }.to raise_error(ActiveRecord::RecordInvalid, /Order items can't be blank/)
      end
    end

    context 'with empty items params' do
      let(:items_params) { {} }

      it 'creates cart but adds no items' do
        expect {
          service.call
        }.to raise_error(ActiveRecord::RecordInvalid, /Order items can't be blank/)
      end
    end
  end
end
