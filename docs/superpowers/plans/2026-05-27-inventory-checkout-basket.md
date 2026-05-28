# Inventory Checkout Basket Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a persistent "add to basket" flow from `/inventories/products/:id` so warehouse staff can queue inventory items into a draft checkout before filling in recipient info.

**Architecture:** `Client::Checkout` gains a `status` enum (`draft` / `confirmed`). A new `Client::CheckoutItem` model stores pending items via `client_inventory_id`. Staff add items from the variants table; `Checkouts::Creator` converts `checkout_items` into `inventory_movements` on finalize and marks the checkout `confirmed`. The existing SKU scan form is wired to POST to the same items endpoint instead of building DOM rows.

**Tech Stack:** Rails 8, Hotwire Turbo Streams, Stimulus, RSpec, FactoryBot, PostgreSQL

---

## File Map

**Create:**
- `db/migrate/TIMESTAMP_add_status_to_client_checkouts.rb`
- `db/migrate/TIMESTAMP_create_client_checkout_items.rb`
- `app/models/client/checkout_item.rb`
- `app/controllers/inventories/items_controller.rb`
- `app/views/inventories/items/create.turbo_stream.erb`
- `app/views/inventories/items/update.turbo_stream.erb`
- `app/views/inventories/items/destroy.turbo_stream.erb`
- `app/views/inventories/items/clear.turbo_stream.erb`
- `app/views/shared/_floating_checkout_basket.html.erb`
- `app/views/checkouts/_draft_items.html.erb`
- `spec/models/client/checkout_item_spec.rb`
- `spec/requests/inventories/items_spec.rb`
- `spec/factories/client/checkout_items.rb`

**Modify:**
- `app/models/client/checkout.rb`
- `app/controllers/base_controller.rb`
- `app/controllers/checkouts_controller.rb`
- `app/controllers/products_controller.rb`
- `app/services/checkouts/creator.rb`
- `app/views/products/_variants_table.html.erb`
- `app/views/checkouts/_form.html.erb`
- `app/views/shared/_inventory_workspace.html.erb`
- `app/javascript/controllers/client/checkout_form_controller.js`
- `config/routes.rb`
- `spec/services/checkouts/creator_spec.rb`
- `spec/factories/client/checkouts.rb`

---

## Task 1: Add `status` to `Client::Checkout`

**Files:**
- Create: `db/migrate/TIMESTAMP_add_status_to_client_checkouts.rb`
- Modify: `app/models/client/checkout.rb`
- Modify: `spec/factories/client/checkouts.rb`
- Modify: `spec/models/client/checkout_spec.rb`

- [ ] **Step 1: Generate the migration**

```bash
docker-compose exec web bin/rails generate migration AddStatusToClientCheckouts status:string
```

- [ ] **Step 2: Edit the migration to set default and backfill**

Open the generated file and replace its content:

```ruby
class AddStatusToClientCheckouts < ActiveRecord::Migration[8.0]
  def change
    add_column :client_checkouts, :status, :string, null: false, default: "confirmed"
    add_index :client_checkouts, :status
  end
end
```

- [ ] **Step 3: Run the migration**

```bash
docker-compose exec web bin/rails db:migrate
```

Expected output: `== AddStatusToClientCheckouts: migrated`

- [ ] **Step 4: Write failing model specs**

Open `spec/models/client/checkout_spec.rb` and add inside the `RSpec.describe` block:

```ruby
describe "status enum" do
  it "defaults to confirmed" do
    checkout = Client::Checkout.new
    expect(checkout.status).to eq("confirmed")
  end

  it "can be set to draft" do
    checkout = Client::Checkout.new(status: :draft)
    expect(checkout).to be_draft
  end
end

describe "validations with draft status" do
  subject(:checkout) { Client::Checkout.new(status: :draft, client: create(:client), user: create(:user, :client)) }

  it "is valid without recipient info" do
    expect(checkout).to be_valid
  end
end

describe "validations with confirmed status" do
  subject(:checkout) { build(:client_checkout, :confirmed) }

  it "requires recipient_email" do
    checkout.recipient_email = nil
    expect(checkout).not_to be_valid
    expect(checkout.errors[:recipient_email]).to be_present
  end

  it "requires recipient_first_name" do
    checkout.recipient_first_name = nil
    expect(checkout).not_to be_valid
  end

  it "requires recipient_last_name" do
    checkout.recipient_last_name = nil
    expect(checkout).not_to be_valid
  end
end
```

- [ ] **Step 5: Run the spec to see it fail**

```bash
docker-compose exec web bundle exec rspec spec/models/client/checkout_spec.rb --format documentation
```

Expected: failures about missing enum and conditional validations.

- [ ] **Step 6: Update `app/models/client/checkout.rb`**

Replace the full file content:

```ruby
class Client::Checkout < ApplicationRecord
  belongs_to :client
  belongs_to :user

  has_many :inventory_movements, class_name: "Client::InventoryMovement", dependent: :nullify, foreign_key: :client_checkout_id
  has_many :checkout_items, class_name: "Client::CheckoutItem", foreign_key: :client_checkout_id, dependent: :destroy

  enum :status, { draft: "draft", confirmed: "confirmed" }, default: :confirmed

  validates :recipient_email, :recipient_first_name, :recipient_last_name, presence: true, if: :confirmed?
  validates :recipient_email, format: { with: URI::MailTo::EMAIL_REGEXP }, if: :confirmed?
  validates :inventory_movements, presence: { message: "at least one item must be added to the checkout" }, if: :confirmed?

  scope :search_by_name, ->(name) {
    where("#{table_name}.recipient_email ILIKE :name OR
          #{table_name}.recipient_first_name ILIKE :name OR
          #{table_name}.recipient_last_name ILIKE :name",
          name: "%#{sanitize_sql_like(name)}%")
  }

  accepts_nested_attributes_for :inventory_movements, allow_destroy: true

  before_save :set_user_for_movements

  def recipient_full_name
    "#{recipient_first_name.humanize} #{recipient_last_name.humanize}"
  end

  private

  def set_user_for_movements
    inventory_movements.each do |movement|
      movement.user = user if movement.user_id.blank?
      movement.quantity = -movement.quantity.abs if movement.movement_type == "stock_out"
    end
  end
end
```

- [ ] **Step 7: Update `spec/factories/client/checkouts.rb`**

```ruby
FactoryBot.define do
  factory :client_checkout, class: "Client::Checkout" do
    association :client
    association :user, factory: :user, role: :client

    trait :draft do
      status { "draft" }
    end

    trait :confirmed do
      status { "confirmed" }
      recipient_email { Faker::Internet.email }
      recipient_first_name { Faker::Name.first_name }
      recipient_last_name { Faker::Name.last_name }
    end
  end
end
```

- [ ] **Step 8: Run the model spec and confirm it passes**

```bash
docker-compose exec web bundle exec rspec spec/models/client/checkout_spec.rb --format documentation
```

Expected: all examples pass.

- [ ] **Step 9: Commit**

```bash
git add db/migrate/*_add_status_to_client_checkouts.rb app/models/client/checkout.rb spec/models/client/checkout_spec.rb spec/factories/client/checkouts.rb
git commit -m "feat: add status enum to Client::Checkout with conditional validations"
```

---

## Task 2: Create `Client::CheckoutItem` model

**Files:**
- Create: `db/migrate/TIMESTAMP_create_client_checkout_items.rb`
- Create: `app/models/client/checkout_item.rb`
- Create: `spec/factories/client/checkout_items.rb`
- Create: `spec/models/client/checkout_item_spec.rb`

- [ ] **Step 1: Generate the migration**

```bash
docker-compose exec web bin/rails generate migration CreateClientCheckoutItems
```

- [ ] **Step 2: Edit the migration**

```ruby
class CreateClientCheckoutItems < ActiveRecord::Migration[8.0]
  def change
    create_table :client_checkout_items do |t|
      t.references :client_checkout, null: false, foreign_key: true
      t.references :client_inventory, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.timestamps
    end

    add_index :client_checkout_items, [:client_checkout_id, :client_inventory_id], unique: true,
              name: "idx_checkout_items_on_checkout_and_inventory"
  end
end
```

- [ ] **Step 3: Run the migration**

```bash
docker-compose exec web bin/rails db:migrate
```

Expected: `== CreateClientCheckoutItems: migrated`

- [ ] **Step 4: Write the failing spec**

Create `spec/models/client/checkout_item_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe Client::CheckoutItem, type: :model do
  subject(:item) { build(:client_checkout_item) }

  describe "associations" do
    it { is_expected.to belong_to(:client_checkout).class_name("Client::Checkout") }
    it { is_expected.to belong_to(:client_inventory).class_name("Client::Inventory") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_numericality_of(:quantity).is_greater_than(0).only_integer }
  end
end
```

- [ ] **Step 5: Run the spec to see it fail**

```bash
docker-compose exec web bundle exec rspec spec/models/client/checkout_item_spec.rb
```

Expected: NameError or failure about missing model.

- [ ] **Step 6: Create `app/models/client/checkout_item.rb`**

```ruby
class Client::CheckoutItem < ApplicationRecord
  belongs_to :client_checkout, class_name: "Client::Checkout", foreign_key: :client_checkout_id
  belongs_to :client_inventory, class_name: "Client::Inventory", foreign_key: :client_inventory_id

  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
end
```

- [ ] **Step 7: Create `spec/factories/client/checkout_items.rb`**

```ruby
FactoryBot.define do
  factory :client_checkout_item, class: "Client::CheckoutItem" do
    association :client_checkout, factory: [:client_checkout, :draft]
    association :client_inventory
    quantity { 1 }
  end
end
```

- [ ] **Step 8: Run the spec and confirm it passes**

```bash
docker-compose exec web bundle exec rspec spec/models/client/checkout_item_spec.rb --format documentation
```

Expected: all examples pass.

- [ ] **Step 9: Commit**

```bash
git add db/migrate/*_create_client_checkout_items.rb app/models/client/checkout_item.rb spec/models/client/checkout_item_spec.rb spec/factories/client/checkout_items.rb
git commit -m "feat: add Client::CheckoutItem model"
```

---

## Task 3: Update routes

**Files:**
- Modify: `config/routes.rb`

- [ ] **Step 1: Open `config/routes.rb` and replace the checkouts resource block**

Find this line (line 64):
```ruby
resources :checkouts, only: [ :index, :show, :new, :create ], as: :inventory_checkouts
```

Replace it with:
```ruby
resources :checkouts, only: [ :index, :show, :new, :create ], as: :inventory_checkouts do
  resources :items, only: [ :create, :update, :destroy ] do
    collection do
      delete :clear
    end
  end
end
```

- [ ] **Step 2: Verify routes are correct**

```bash
docker-compose exec web bin/rails routes | grep "inventory_checkout.*items"
```

Expected output (column order may vary):
```
clear_inventory_checkout_items  DELETE  /inventories/checkouts/:checkout_id/items/clear(.:format)
      inventory_checkout_items  POST    /inventories/checkouts/:checkout_id/items(.:format)
       inventory_checkout_item  PATCH   /inventories/checkouts/:checkout_id/items/:id(.:format)
       inventory_checkout_item  DELETE  /inventories/checkouts/:checkout_id/items/:id(.:format)
```

- [ ] **Step 3: Commit**

```bash
git add config/routes.rb
git commit -m "feat: add nested items routes under inventory checkouts"
```

---

## Task 4: Update `BaseController` — basket count helper

**Files:**
- Modify: `app/controllers/base_controller.rb`

- [ ] **Step 1: Add `checkout_basket_count` helper and add `"items"` to inventory controller list**

Open `app/controllers/base_controller.rb` and replace the full file:

```ruby
class BaseController < ApplicationController
  before_action :check_user
  before_action :set_current_client
  before_action :check_inventories_access
  before_action :cart_items_count
  before_action :checkout_basket_count

  INVENTORIES_ENABLED_CONTROLLER = [ "inventories", "inventory_movements", "items" ].freeze

  def current_client
    @current_client
  end

  def cart_items_count
    @cart_items_count ||= current_user&.in_cart_order&.order_items&.sum(:quantity) || 0
  end
  helper_method :cart_items_count

  def checkout_basket_count
    @checkout_basket_count ||= begin
      draft = current_client&.checkouts&.find_by(status: :draft, user: current_user)
      draft&.checkout_items&.sum(:quantity) || 0
    end
  end
  helper_method :checkout_basket_count

  def check_inventories_access
    return true unless INVENTORIES_ENABLED_CONTROLLER.include?(controller_name)

    unless @current_client.inventory_enabled
      redirect_to root_path, alert: "Inventory access is disabled."
    end
  end

  private

  def check_user
    unless current_user&.role_client?
      redirect_to admin_root_path, alert: "Access denied."
    end
  end

  def set_current_client
    @current_client ||= current_user.client
  end
end
```

- [ ] **Step 2: Verify app boots with no errors**

```bash
docker-compose exec web bin/rails runner "puts 'OK'"
```

Expected: `OK`

- [ ] **Step 3: Commit**

```bash
git add app/controllers/base_controller.rb
git commit -m "feat: add checkout_basket_count helper to BaseController"
```

---

## Task 5: Create `Inventories::ItemsController`

**Files:**
- Create: `app/controllers/inventories/items_controller.rb`
- Create: `spec/requests/inventories/items_spec.rb`

- [ ] **Step 1: Write the failing request spec**

Create `spec/requests/inventories/items_spec.rb`:

```ruby
require "rails_helper"

RSpec.describe "Inventories::Items", type: :request do
  let(:client) { create(:client, inventory_enabled: true) }
  let(:user) { create(:user, :client, client: client) }
  let(:draft_checkout) { create(:client_checkout, :draft, client: client, user: user) }
  let(:client_product) { create(:client_product, :with_variants, :without_admin_product, client: client) }
  let(:variant) { client_product.product_variants.first }
  let(:inventory) { create(:client_inventory, client: client, client_product_variant: variant, quantity: 10) }

  before { sign_in user }

  describe "POST /inventories/checkouts/:checkout_id/items" do
    it "creates a checkout item and responds with turbo stream" do
      post inventory_checkout_items_path(draft_checkout),
           params: { client_inventory_id: inventory.id, quantity: 2 },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(Client::CheckoutItem.count).to eq(1)
      expect(Client::CheckoutItem.last.quantity).to eq(2)
    end

    it "increments quantity when item already exists" do
      create(:client_checkout_item, client_checkout: draft_checkout, client_inventory: inventory, quantity: 3)

      post inventory_checkout_items_path(draft_checkout),
           params: { client_inventory_id: inventory.id, quantity: 2 },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(Client::CheckoutItem.count).to eq(1)
      expect(Client::CheckoutItem.last.quantity).to eq(5)
    end

    it "returns 404 for inventory not belonging to client" do
      other_inventory = create(:client_inventory, quantity: 5)

      post inventory_checkout_items_path(draft_checkout),
           params: { client_inventory_id: other_inventory.id, quantity: 1 },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /inventories/checkouts/:checkout_id/items/:id" do
    let!(:item) { create(:client_checkout_item, client_checkout: draft_checkout, client_inventory: inventory, quantity: 3) }

    it "updates quantity" do
      patch inventory_checkout_item_path(draft_checkout, item),
            params: { quantity: 5 },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(item.reload.quantity).to eq(5)
    end

    it "destroys item when quantity is 0" do
      patch inventory_checkout_item_path(draft_checkout, item),
            params: { quantity: 0 },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(Client::CheckoutItem.find_by(id: item.id)).to be_nil
    end
  end

  describe "DELETE /inventories/checkouts/:checkout_id/items/:id" do
    let!(:item) { create(:client_checkout_item, client_checkout: draft_checkout, client_inventory: inventory, quantity: 3) }

    it "destroys the item" do
      delete inventory_checkout_item_path(draft_checkout, item),
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(Client::CheckoutItem.find_by(id: item.id)).to be_nil
    end
  end

  describe "DELETE /inventories/checkouts/:checkout_id/items/clear" do
    before do
      create(:client_checkout_item, client_checkout: draft_checkout, client_inventory: inventory, quantity: 2)
    end

    it "destroys all items" do
      delete clear_inventory_checkout_items_path(draft_checkout),
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(draft_checkout.reload.checkout_items.count).to eq(0)
    end
  end
end
```

- [ ] **Step 2: Run the spec to see it fail**

```bash
docker-compose exec web bundle exec rspec spec/requests/inventories/items_spec.rb
```

Expected: routing error or NameError — controller doesn't exist yet.

- [ ] **Step 3: Create `app/controllers/inventories/items_controller.rb`**

```ruby
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
```

- [ ] **Step 4: Run the spec**

```bash
docker-compose exec web bundle exec rspec spec/requests/inventories/items_spec.rb --format documentation
```

Expected: failures about missing turbo stream views (template missing) — controller exists but views don't yet. If you see routing errors, double-check routes from Task 3.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/inventories/items_controller.rb spec/requests/inventories/items_spec.rb
git commit -m "feat: add Inventories::ItemsController"
```

---

## Task 6: Create Turbo Stream views for items

**Files:**
- Create: `app/views/inventories/items/create.turbo_stream.erb`
- Create: `app/views/inventories/items/update.turbo_stream.erb`
- Create: `app/views/inventories/items/destroy.turbo_stream.erb`
- Create: `app/views/inventories/items/clear.turbo_stream.erb`

- [ ] **Step 1: Create the directory**

```bash
mkdir -p /Users/emheri/Workspace/personal/shirtpop/reordersweb/app/views/inventories/items
```

- [ ] **Step 2: Create `app/views/inventories/items/create.turbo_stream.erb`**

```erb
<%# Update the floating basket badge on all inventory pages %>
<%= turbo_stream.replace "floating-checkout-basket" do %>
  <%= render "shared/floating_checkout_basket" %>
<% end %>

<%# Update draft items table if user is on the checkout form %>
<%= turbo_stream.replace "checkout-draft-items" do %>
  <%= render "checkouts/draft_items", checkout: @checkout %>
<% end %>
```

- [ ] **Step 3: Create `app/views/inventories/items/update.turbo_stream.erb`**

```erb
<%= turbo_stream.replace "floating-checkout-basket" do %>
  <%= render "shared/floating_checkout_basket" %>
<% end %>

<%= turbo_stream.replace "checkout-draft-items" do %>
  <%= render "checkouts/draft_items", checkout: @checkout %>
<% end %>
```

- [ ] **Step 4: Create `app/views/inventories/items/destroy.turbo_stream.erb`**

```erb
<%= turbo_stream.replace "floating-checkout-basket" do %>
  <%= render "shared/floating_checkout_basket" %>
<% end %>

<%= turbo_stream.replace "checkout-draft-items" do %>
  <%= render "checkouts/draft_items", checkout: @checkout %>
<% end %>
```

- [ ] **Step 5: Create `app/views/inventories/items/clear.turbo_stream.erb`**

```erb
<%= turbo_stream.replace "floating-checkout-basket" do %>
  <%= render "shared/floating_checkout_basket" %>
<% end %>

<%= turbo_stream.replace "checkout-draft-items" do %>
  <%= render "checkouts/draft_items", checkout: @checkout %>
<% end %>
```

- [ ] **Step 6: Run the request spec again — expect it to pass now**

```bash
docker-compose exec web bundle exec rspec spec/requests/inventories/items_spec.rb --format documentation
```

Expected: all examples pass. If you get a `draft_items` partial missing error, that's expected — it's created in Task 12. Create a placeholder for now:

```bash
mkdir -p app/views/checkouts
echo '<div id="checkout-draft-items"></div>' > app/views/checkouts/_draft_items.html.erb
```

Re-run to confirm all pass.

- [ ] **Step 7: Commit**

```bash
git add app/views/inventories/items/
git commit -m "feat: add Turbo Stream views for inventory checkout items"
```

---

## Task 7: Floating checkout basket partial + wire into layout

**Files:**
- Create: `app/views/shared/_floating_checkout_basket.html.erb`
- Modify: `app/views/shared/_inventory_workspace.html.erb`

- [ ] **Step 1: Create `app/views/shared/_floating_checkout_basket.html.erb`**

```erb
<div id="floating-checkout-basket">
  <% if checkout_basket_count > 0 %>
    <%= link_to new_inventory_checkout_path, class: "group fixed bottom-8 right-28 z-50", data: { turbo_frame: "_top" } do %>
      <div class="relative flex items-center gap-3 px-6 py-4 bg-gradient-to-r from-indigo-600 to-violet-600 hover:from-indigo-700 hover:to-violet-700 text-white font-bold rounded-2xl shadow-2xl hover:shadow-indigo-500/40 transition-all duration-300 transform hover:-translate-y-1 hover:scale-105">
        <svg class="w-6 h-6 transition-transform duration-200 group-hover:scale-110" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"></path>
        </svg>
        <span>Basket</span>
        <span class="absolute -top-2.5 -right-2.5 bg-gradient-to-br from-yellow-400 to-orange-500 text-gray-900 text-xs font-bold rounded-full h-7 w-7 flex items-center justify-center shadow-lg border-2 border-white animate-bounce">
          <%= checkout_basket_count %>
        </span>
      </div>
    <% end %>
  <% end %>
</div>
```

- [ ] **Step 2: Modify `app/views/shared/_inventory_workspace.html.erb`**

Replace the full file:

```erb
<div class="container mx-auto px-4 py-8 max-w-7xl">
  <div class="space-y-8">
    <%= render "shared/inventory_header" %>

    <div class="bg-white rounded-2xl shadow-lg border-2 border-gray-200 overflow-hidden">
      <div class="p-6 md:p-8">
        <%= body %>
      </div>
    </div>
  </div>
</div>

<%= render "shared/floating_checkout_basket" %>
```

- [ ] **Step 3: Boot the app and navigate to `/inventories/products` — verify the basket button appears when there are draft items**

```bash
docker-compose exec web bin/dev
```

Open http://localhost:3000, log in as a client user with inventory enabled, create a draft checkout via rails console, navigate to `/inventories/products`. The indigo basket button should appear bottom-right if draft items exist.

- [ ] **Step 4: Commit**

```bash
git add app/views/shared/_floating_checkout_basket.html.erb app/views/shared/_inventory_workspace.html.erb
git commit -m "feat: add floating checkout basket button to inventory layout"
```

---

## Task 8: Update `Checkouts::Creator` to read from `checkout_items`

**Files:**
- Modify: `app/services/checkouts/creator.rb`
- Modify: `spec/services/checkouts/creator_spec.rb`

- [ ] **Step 1: Rewrite `spec/services/checkouts/creator_spec.rb`**

Replace the full file content:

```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Checkouts::Creator, type: :service do
  let(:client) { create(:client) }
  let(:user) { create(:user, :client, client: client) }
  let(:client_product) { create(:client_product, :with_variants, :without_admin_product, client: client) }
  let(:variant) { client_product.product_variants.first }
  let(:inventory) { create(:client_inventory, client: client, client_product_variant: variant, quantity: 50) }
  let(:checkout) { create(:client_checkout, :draft, client: client, user: user) }
  let!(:checkout_item) { create(:client_checkout_item, client_checkout: checkout, client_inventory: inventory, quantity: 5) }

  subject(:creator) { described_class.new(user: user, checkout: checkout) }

  describe "#initialize" do
    it "sets user and checkout attributes" do
      aggregate_failures do
        expect(creator.user).to eq(user)
        expect(creator.checkout).to eq(checkout)
      end
    end
  end

  describe "#call!" do
    context "when checkout creation is successful" do
      it "marks checkout as confirmed" do
        creator.call!
        expect(checkout.reload.status).to eq("confirmed")
      end

      it "sets recipient info (assigned before calling creator)" do
        checkout.update!(
          recipient_email: "test@example.com",
          recipient_first_name: "Test",
          recipient_last_name: "User",
          status: :draft
        )
        creator.call!
        expect(checkout.reload.recipient_email).to eq("test@example.com")
      end

      it "creates inventory_movements for each checkout_item" do
        expect { creator.call! }.to change(Client::InventoryMovement, :count).by(1)

        movement = checkout.reload.inventory_movements.first
        aggregate_failures do
          expect(movement.client_inventory).to eq(inventory)
          expect(movement.movement_type).to eq("stock_out")
          expect(movement.quantity).to eq(-5)
          expect(movement.user).to eq(user)
        end
      end

      it "decrements inventory quantities" do
        expect { creator.call! }.to change { inventory.reload.quantity }.from(50).to(45)
      end

      it "uses database locks to prevent race conditions" do
        expect_any_instance_of(Client::Inventory).to receive(:with_lock).and_call_original
        creator.call!
      end
    end

    context "when checkout has no items" do
      before { checkout_item.destroy! }

      it "raises CheckoutCreationError" do
        expect { creator.call! }.to raise_error(Checkouts::Creator::CheckoutCreationError, /No items/)
      end

      it "does not mark checkout as confirmed" do
        expect { creator.call! rescue nil }.not_to change { checkout.reload.status }
      end
    end

    context "when inventory has insufficient stock" do
      let!(:checkout_item) { create(:client_checkout_item, client_checkout: checkout, client_inventory: inventory, quantity: 60) }

      it "raises StockUpdateError" do
        expect { creator.call! }.to raise_error(Checkouts::Creator::StockUpdateError, /Insufficient stock/)
      end

      it "does not mark checkout as confirmed" do
        expect { creator.call! rescue nil }.not_to change { checkout.reload.status }
      end

      it "does not update inventory quantities" do
        expect { creator.call! rescue nil }.not_to change { inventory.reload.quantity }
      end
    end

    context "with multiple checkout items" do
      let(:variant2) { client_product.product_variants.second }
      let(:inventory2) { create(:client_inventory, client: client, client_product_variant: variant2, quantity: 30) }
      let!(:checkout_item2) { create(:client_checkout_item, client_checkout: checkout, client_inventory: inventory2, quantity: 10) }

      it "processes all items and decrements stock" do
        creator.call!
        expect(inventory.reload.quantity).to eq(45)
        expect(inventory2.reload.quantity).to eq(20)
      end

      it "rolls back all changes if any item fails" do
        checkout_item2.update_column(:quantity, 40)

        expect { creator.call! }.to raise_error(Checkouts::Creator::StockUpdateError)

        expect(inventory.reload.quantity).to eq(50)
        expect(inventory2.reload.quantity).to eq(30)
      end
    end

    context "transaction behavior" do
      it "wraps the entire operation in a transaction" do
        allow_any_instance_of(Client::Inventory).to receive(:with_lock).and_raise(StandardError, "DB error")

        expect { creator.call! }.to raise_error(StandardError, "DB error")
        expect(inventory.reload.quantity).to eq(50)
      end
    end
  end

  describe "#success?" do
    it "returns true after successful call" do
      creator.call!
      expect(creator.success?).to be true
    end

    it "returns false before call" do
      expect(creator.success?).to be false
    end
  end

  describe "error classes" do
    it { expect(Checkouts::Creator::Error).to be < StandardError }
    it { expect(Checkouts::Creator::CheckoutCreationError).to be < Checkouts::Creator::Error }
    it { expect(Checkouts::Creator::StockUpdateError).to be < Checkouts::Creator::Error }
  end
end
```

- [ ] **Step 2: Run the spec to see it fail**

```bash
docker-compose exec web bundle exec rspec spec/services/checkouts/creator_spec.rb --format documentation
```

Expected: failures because the creator still reads `inventory_movements_attributes`.

- [ ] **Step 3: Rewrite `app/services/checkouts/creator.rb`**

```ruby
# frozen_string_literal: true

module Checkouts
  class Creator
    class Error < StandardError; end
    class CheckoutCreationError < Error; end
    class StockUpdateError < Error; end

    attr_reader :checkout, :user

    def initialize(user:, checkout:)
      @user = user
      @checkout = checkout
    end

    def call!
      validate_items!
      validate_stock!

      ActiveRecord::Base.transaction do
        begin
          set_user_and_status
          checkout.save!

          checkout.checkout_items.each do |item|
            inventory = item.client_inventory
            raise StockUpdateError, "Missing inventory for item #{item.id}" unless inventory

            inventory.with_lock do
              raise StockUpdateError, "Insufficient stock for #{inventory.id}" if inventory.quantity < item.quantity

              inventory.decrement!(:quantity, item.quantity)
            end

            checkout.inventory_movements.create!(
              client_inventory: inventory,
              quantity: -item.quantity.abs,
              movement_type: :stock_out,
              user: user
            )
          end

          @checkout
        rescue ActiveRecord::RecordInvalid
          raise CheckoutCreationError, "Failed to create checkout: #{checkout.errors.full_messages.join(', ')}"
        end
      end
    end

    def success?
      checkout.persisted? && checkout.confirmed? && checkout.errors.empty?
    end

    private

    def validate_items!
      raise CheckoutCreationError, "No items in checkout" if checkout.checkout_items.empty?
    end

    def validate_stock!
      checkout.checkout_items.each do |item|
        inventory = item.client_inventory
        raise StockUpdateError, "Missing inventory for item #{item.id}" unless inventory
        raise StockUpdateError, "Insufficient stock for #{inventory.id}" if inventory.quantity < item.quantity
      end
    end

    def set_user_and_status
      checkout.user = user
      checkout.status = :confirmed
    end
  end
end
```

- [ ] **Step 4: Run the spec and confirm it passes**

```bash
docker-compose exec web bundle exec rspec spec/services/checkouts/creator_spec.rb --format documentation
```

Expected: all examples pass.

- [ ] **Step 5: Commit**

```bash
git add app/services/checkouts/creator.rb spec/services/checkouts/creator_spec.rb
git commit -m "feat: update Checkouts::Creator to read from checkout_items"
```

---

## Task 9: Update `CheckoutsController` and `ProductsController`

**Files:**
- Modify: `app/controllers/checkouts_controller.rb`
- Modify: `app/controllers/products_controller.rb`

- [ ] **Step 1: Rewrite `app/controllers/checkouts_controller.rb`**

```ruby
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
```

- [ ] **Step 2: Update `ProductsController#show` to load draft checkout**

In `app/controllers/products_controller.rb`, replace the `show` method:

```ruby
def show
  if params[:catalog_id].present?
    show_storefront_product
  else
    @product = current_client.client_products.find(params[:id])
    @draft_checkout = current_client.checkouts.find_or_create_by!(status: :draft, user: current_user)
  end
end
```

- [ ] **Step 3: Boot the app and verify `/inventories/products/:id` loads without error**

```bash
docker-compose exec web bin/rails runner "puts 'OK'"
```

Navigate to a product show page in the browser and confirm no errors.

- [ ] **Step 4: Commit**

```bash
git add app/controllers/checkouts_controller.rb app/controllers/products_controller.rb
git commit -m "feat: update CheckoutsController and ProductsController for draft basket"
```

---

## Task 10: Update variants table view — add basket row action

**Files:**
- Modify: `app/views/products/_variants_table.html.erb`

- [ ] **Step 1: Open `app/views/products/_variants_table.html.erb` and add a Qty + Add to Basket column**

Replace the `<thead>` and each `<tr>` inside `<tbody>` — find the `<th>` header block and add one more column, then add a form cell to each data row.

Replace the thead block (the `<tr>` inside `<thead class="bg-gray-50">`):

```erb
<thead class="bg-gray-50">
  <tr>
    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Color</th>
    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Size</th>
    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">SKU</th>
    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Barcode</th>
    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Quantity</th>
    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
    <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Actions</th>
    <% if defined?(@draft_checkout) && @draft_checkout %>
      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Add to Basket</th>
    <% end %>
  </tr>
</thead>
```

Then, inside each `<tr>` in the `<tbody>`, after the existing last `<td>` (Actions), add:

```erb
<% if defined?(@draft_checkout) && @draft_checkout %>
  <td class="px-6 py-4 whitespace-nowrap">
    <% if variant.inventory&.quantity.to_i > 0 %>
      <%= form_with url: inventory_checkout_items_path(@draft_checkout),
                    method: :post,
                    data: { turbo_stream: true },
                    class: "flex items-center gap-2" do |f| %>
        <%= f.hidden_field :client_inventory_id, value: variant.inventory.id %>
        <%= f.number_field :quantity, value: 1, min: 1, max: variant.inventory.quantity,
              class: "w-16 px-2 py-1 border border-gray-300 rounded-md text-sm text-center focus:ring-pink-500 focus:border-pink-500" %>
        <%= f.submit "+ Add",
              class: "inline-flex items-center px-3 py-1.5 text-xs font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg transition-colors cursor-pointer" %>
      <% end %>
    <% else %>
      <span class="text-xs text-red-500 font-medium">Out of stock</span>
    <% end %>
  </td>
<% end %>
```

- [ ] **Step 2: Verify in browser — navigate to `/inventories/products/:id`**

Each variant row with stock > 0 should show a quantity input and "+ Add" button. Out of stock rows show "Out of stock" text. Clicking "+ Add" should update the floating basket badge without a page reload.

- [ ] **Step 3: Commit**

```bash
git add app/views/products/_variants_table.html.erb
git commit -m "feat: add Add to Basket form to inventory variants table"
```

---

## Task 11: Update checkout form — draft items partial + notice banner

**Files:**
- Modify: `app/views/checkouts/_draft_items.html.erb` (replace the placeholder from Task 6)
- Modify: `app/views/checkouts/_form.html.erb`

- [ ] **Step 1: Create `app/views/checkouts/_draft_items.html.erb`**

Replace the placeholder created in Task 6 with the full partial:

```erb
<div id="checkout-draft-items">
  <% if checkout.checkout_items.any? %>
    <div class="overflow-x-auto">
      <table class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Product</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">SKU</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Color</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Size</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Available</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Quantity</th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Remove</th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-200">
          <% checkout.checkout_items.includes(client_inventory: { client_product_variant: :client_product }).each do |item| %>
            <% variant = item.client_inventory.client_product_variant %>
            <% inventory = item.client_inventory %>
            <tr>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900"><%= variant.client_product.name %></td>
              <td class="px-6 py-4 whitespace-nowrap">
                <span class="font-mono text-xs bg-gray-100 px-2 py-1 rounded"><%= variant.sku %></span>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900"><%= variant.color.presence || "—" %></td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900"><%= variant.size.presence || "—" %></td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500"><%= inventory.quantity %> units</td>
              <td class="px-6 py-4 whitespace-nowrap">
                <%= form_with url: inventory_checkout_item_path(checkout, item),
                              method: :patch,
                              data: { controller: "cart-item", turbo_stream: true } do |f| %>
                  <div class="flex items-center gap-1" data-cart-item-target="form">
                    <%= f.number_field :quantity, value: item.quantity, min: 0, max: inventory.quantity,
                          class: "w-16 px-2 py-1 border border-gray-300 rounded-md text-sm text-center focus:ring-pink-500 focus:border-pink-500",
                          data: { "cart-item-target": "quantityInput", action: "input->cart-item#updateQuantity" } %>
                  </div>
                <% end %>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <%= button_to inventory_checkout_item_path(checkout, item),
                      method: :delete,
                      class: "p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors",
                      data: { turbo_stream: true } do %>
                  <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
                  </svg>
                <% end %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
  <% else %>
    <div class="px-6 py-8 text-center">
      <svg class="mx-auto h-12 w-12 text-gray-400 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"></path>
      </svg>
      <p class="text-sm text-gray-500">No items yet. Search by SKU above or browse products to add items.</p>
    </div>
  <% end %>
</div>
```

- [ ] **Step 2: Update `app/views/checkouts/_form.html.erb`**

Replace the full file:

```erb
<div class="max-w-5xl mx-auto">
  <div class="mb-6">
    <h2 class="text-2xl font-bold text-gray-900">Create Checkout</h2>
    <p class="mt-1 text-sm text-gray-600">Fill in recipient information and confirm your items</p>
  </div>

  <%# Draft items notice banner %>
  <% if defined?(@has_draft_items) && @has_draft_items %>
    <div class="mb-6 flex items-center justify-between gap-4 rounded-lg border border-indigo-200 bg-indigo-50 px-4 py-3">
      <div class="flex items-center gap-2 text-sm text-indigo-800">
        <svg class="h-5 w-5 text-indigo-600 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
        </svg>
        You have <strong><%= checkout.checkout_items.sum(:quantity) %> item(s)</strong> from a previous session. Continue or clear to start fresh.
      </div>
      <%= button_to "Clear basket",
            clear_inventory_checkout_items_path(checkout),
            method: :delete,
            class: "inline-flex items-center px-3 py-1.5 text-xs font-semibold text-red-700 bg-white border border-red-300 rounded-lg hover:bg-red-50 transition-colors",
            data: { turbo_stream: true, turbo_confirm: "Clear all items from your basket?" } %>
    </div>
  <% end %>

  <%= form_with model: checkout, url: inventory_checkouts_path, method: :post, class: "space-y-6", data: { controller: "checkout-form", "checkout-form-checkout-id-value": checkout.id } do |form| %>
    <!-- Recipient Information Card -->
    <div class="bg-white shadow-sm rounded-lg border border-gray-200 overflow-hidden">
      <div class="px-6 py-4 bg-gray-50 border-b border-gray-200">
        <h3 class="text-lg font-medium text-gray-900">Recipient Information</h3>
      </div>
      <div class="p-6 space-y-4">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <%= form.label :recipient_first_name, "First Name", class: "block text-sm font-medium text-gray-700 mb-1" %>
            <%= form.text_field :recipient_first_name,
                class: "block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-pink-500 focus:border-pink-500 sm:text-sm",
                placeholder: "John" %>
            <%= display_field_errors(checkout, :recipient_first_name) %>
          </div>
          <div>
            <%= form.label :recipient_last_name, "Last Name", class: "block text-sm font-medium text-gray-700 mb-1" %>
            <%= form.text_field :recipient_last_name,
                class: "block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-pink-500 focus:border-pink-500 sm:text-sm",
                placeholder: "Doe" %>
            <%= display_field_errors(checkout, :recipient_last_name) %>
          </div>
        </div>
        <div>
          <%= form.label :recipient_email, "Email Address", class: "block text-sm font-medium text-gray-700 mb-1" %>
          <%= form.email_field :recipient_email,
              class: "block w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-pink-500 focus:border-pink-500 sm:text-sm",
              placeholder: "john.doe@example.com" %>
          <%= display_field_errors(checkout, :recipient_email) %>
        </div>
      </div>
    </div>

    <!-- Items Section -->
    <div class="bg-white shadow-sm rounded-lg border border-gray-200 overflow-hidden">
      <div class="px-6 py-4 bg-gray-50 border-b border-gray-200">
        <h3 class="text-lg font-medium text-gray-900">Checkout Items</h3>
      </div>

      <!-- SKU Search -->
      <div class="p-6 border-b border-gray-200">
        <div class="flex items-start space-x-4 mb-4">
          <div class="max-w-md flex-1">
            <div class="flex items-center justify-between mb-1">
              <%= label_tag :sku_search, "Search by SKU", class: "block text-sm font-medium text-gray-700" %>
              <span class="inline-flex items-center text-xs text-gray-500">
                <svg class="h-4 w-4 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z"></path>
                </svg>
                Barcode scanner ready
              </span>
            </div>
            <div class="relative">
              <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                <svg class="h-5 w-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path>
                </svg>
              </div>
              <%= text_field_tag :sku_search, "",
                  class: "block w-full pl-10 pr-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-pink-500 focus:border-pink-500 sm:text-sm",
                  placeholder: "Scan barcode or type SKU",
                  autofocus: true,
                  data: {
                    "checkout-form-target": "skuInput",
                    action: "keydown->checkout-form#handleSkuSearch"
                  } %>
            </div>
            <p class="mt-1 text-xs text-gray-500">Press Enter to add item to basket</p>
          </div>

          <div class="flex flex-col space-y-2 pt-6">
            <button type="button"
                    class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-pink-600 hover:bg-pink-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-pink-500"
                    data-action="click->checkout-form#searchSkuButton">
              <svg class="h-5 w-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"></path>
              </svg>
              Add Item
            </button>
          </div>
        </div>

        <div data-checkout-form-target="searchError" class="hidden mt-2">
          <p class="text-sm text-red-600"></p>
        </div>
        <div data-checkout-form-target="successMessage" class="hidden mt-2">
          <div class="flex items-center text-sm text-green-600">
            <svg class="h-4 w-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"></path>
            </svg>
            <span></span>
          </div>
        </div>
      </div>

      <!-- Items Table (server-rendered from draft checkout_items) -->
      <%= render "checkouts/draft_items", checkout: checkout %>
    </div>

    <!-- Form Actions -->
    <div class="flex items-center justify-between">
      <%= link_to inventory_checkouts_path,
            class: "inline-flex items-center px-4 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-pink-500",
            data: { turbo_frame: "_top" } do %>
        <svg class="h-4 w-4 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"></path>
        </svg>
        Cancel
      <% end %>
      <%= form.submit "Create Checkout",
          class: "inline-flex items-center px-6 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-pink-600 hover:bg-pink-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-pink-500" %>
    </div>
  <% end %>
</div>
```

- [ ] **Step 3: Commit**

```bash
git add app/views/checkouts/_draft_items.html.erb app/views/checkouts/_form.html.erb
git commit -m "feat: update checkout form to show draft items with notice banner"
```

---

## Task 12: Update `checkout_form_controller.js` — wire SKU scan to items endpoint

**Files:**
- Modify: `app/javascript/controllers/client/checkout_form_controller.js`

The current controller builds DOM rows via `addItem()` and uses `inventory_movements_attributes` nested form fields. We replace this with a server POST that returns a Turbo Stream.

- [ ] **Step 1: Replace `app/javascript/controllers/client/checkout_form_controller.js`**

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "skuInput",
    "searchError",
    "successMessage",
  ]

  static values = {
    checkoutId: Number
  }

  connect() {
    this.searchTimeout = null
  }

  preventSubmit(event) {
    if (document.activeElement === this.skuInputTarget) {
      event.preventDefault()
      return false
    }
  }

  handleSkuSearch(event) {
    if (event.key === "Enter" || event.keyCode === 13) {
      event.preventDefault()
      event.stopPropagation()
      this.searchSku()
    }
  }

  searchSkuButton(event) {
    event.preventDefault()
    event.stopPropagation()
    this.searchSku()
  }

  async searchSku() {
    const sku = this.skuInputTarget.value.trim()

    if (!sku) {
      this.showError("Please enter a SKU")
      return
    }

    this.hideError()
    this.skuInputTarget.disabled = true

    try {
      const response = await fetch(`/inventories/product_variants/${encodeURIComponent(sku)}`, {
        headers: {
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
        }
      })

      if (!response.ok) throw new Error("Product variant not found")

      const variant = await response.json()

      if (!variant.inventory_id || variant.quantity <= 0) {
        this.showError("This item is out of stock")
        return
      }

      const added = await this.addToBasket(variant.inventory_id, 1)
      if (added) {
        this.skuInputTarget.value = ""
        this.showSuccess(`${variant.product_name} (${variant.sku}) added to basket`)
      }
    } catch (error) {
      this.showError(error.message || "Product not found. Please check the SKU and try again.")
    } finally {
      this.skuInputTarget.disabled = false
      this.skuInputTarget.focus()
    }
  }

  async addToBasket(inventoryId, quantity) {
    try {
      const response = await fetch(
        `/inventories/checkouts/${this.checkoutIdValue}/items`,
        {
          method: "POST",
          headers: {
            "Accept": "text/vnd.turbo-stream.html",
            "Content-Type": "application/json",
            "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
          },
          body: JSON.stringify({ client_inventory_id: inventoryId, quantity })
        }
      )

      if (!response.ok) throw new Error("Failed to add item to basket")

      const html = await response.text()
      window.Turbo.renderStreamMessage(html)
      return true
    } catch (error) {
      this.showError(error.message || "Failed to add item to basket")
      return false
    }
  }

  showError(message) {
    this.hideSuccess()
    this.searchErrorTarget.querySelector("p").textContent = message
    this.searchErrorTarget.classList.remove("hidden")
    setTimeout(() => this.hideError(), 3000)
  }

  hideError() {
    this.searchErrorTarget.classList.add("hidden")
  }

  showSuccess(message) {
    this.hideError()
    if (this.hasSuccessMessageTarget) {
      this.successMessageTarget.querySelector("span").textContent = message
      this.successMessageTarget.classList.remove("hidden")
      setTimeout(() => this.hideSuccess(), 2000)
    }
  }

  hideSuccess() {
    if (this.hasSuccessMessageTarget) {
      this.successMessageTarget.classList.add("hidden")
    }
  }
}
```

- [ ] **Step 2: Verify the form `data` attribute passes `checkout-id` value**

The form in `_form.html.erb` already has `data: { "checkout-form-checkout-id-value": checkout.id }` (added in Task 11). Confirm this is present.

- [ ] **Step 3: Test the full flow in the browser**

1. Navigate to `/inventories/checkouts/new`
2. Scan/type a SKU and press Enter
3. Confirm the item appears in the draft items table without a page reload
4. Confirm the floating basket badge updates
5. Fill in recipient info and click "Create Checkout"
6. Confirm redirect to checkout list with success notice

- [ ] **Step 4: Commit**

```bash
git add app/javascript/controllers/client/checkout_form_controller.js
git commit -m "feat: wire checkout form SKU scan to items endpoint via Turbo Stream"
```

---

## Task 13: Final smoke test

- [ ] **Step 1: Run the full test suite**

```bash
docker-compose exec web bundle exec rspec --format progress
```

Expected: no failures. If any existing specs broke due to the `Checkouts::Creator` change (e.g., request specs for checkouts that use the old nested attributes approach), update them to use `create(:client_checkout, :draft)` + `create(:client_checkout_item, ...)`.

- [ ] **Step 2: Manual end-to-end walkthrough**

**Path A — Add from products page:**
1. Log in as a client user with `inventory_enabled: true`
2. Go to `/inventories/products`, click a product
3. On the variants table, type a quantity and click "+ Add" on a row with stock
4. Confirm the indigo basket badge appears/increments bottom-right
5. Click the basket badge → goes to `/inventories/checkouts/new`
6. Confirm items appear in the draft items table
7. Fill in recipient info → submit → confirm redirect + checkout in list

**Path B — Add from checkout form SKU scan:**
1. Go to `/inventories/checkouts/new` directly
2. Scan/type a SKU → item appears in table
3. Adjust quantity in table → quantity updates without reload
4. Click remove → item disappears
5. Fill in recipient → submit → success

**Path C — Draft notice:**
1. Add items via Path A but don't submit
2. Navigate to `/inventories/checkouts/new` again
3. Confirm the indigo notice banner appears with item count and "Clear basket" button
4. Click "Clear basket" → table empties, basket badge disappears

- [ ] **Step 3: Final commit**

```bash
git add .
git commit -m "feat: inventory checkout basket — complete implementation"
```
