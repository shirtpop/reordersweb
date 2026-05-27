# Inventory Checkout Basket

**Date:** 2026-05-27  
**Status:** Approved

## Overview

Add a persistent "add to basket" entry point from `/inventories/products/:id` for the inventory checkout flow. Staff browse their inventory products, add variants directly from the variants table, and finalize with recipient info when ready. The existing SKU scan form remains unchanged — both paths write to the same draft checkout.

**Who uses this:** Warehouse staff (power users) distributing inventory to recipients.

---

## Data Model

### `Client::Checkout` — add `status` column

| value | meaning |
|---|---|
| `draft` | basket being built, stock not yet decremented |
| `confirmed` | submitted, stock decremented, recipient set |

Migration defaults all existing rows to `confirmed`.

**Model validation changes required:** The current `Client::Checkout` model validates `recipient_email`, `recipient_first_name`, `recipient_last_name` presence unconditionally, and requires `inventory_movements` to be present. These must be made conditional on `status == :confirmed` so a draft can be saved without recipient info or items:

```ruby
validates :recipient_email, :recipient_first_name, :recipient_last_name, presence: true, if: :confirmed?
validates :recipient_email, format: { with: URI::MailTo::EMAIL_REGEXP }, if: :confirmed?
validates :inventory_movements, presence: { message: "at least one item must be added" }, if: :confirmed?
```

### New: `Client::CheckoutItem`

Holds pending items before they become `inventory_movements`.

| column | type | notes |
|---|---|---|
| `client_checkout_id` | FK | the draft checkout |
| `client_inventory_id` | FK | carries color + size + SKU via the inventory record |
| `quantity` | integer | must be > 0 |
| `created_at` / `updated_at` | timestamps | |

**Why `client_inventory_id` over `product_variant_id`:**
- Consistent with `Client::InventoryMovement` (same FK pattern)
- Implicit validation — item can only be created if an inventory record exists
- No extra lookup on finalize; `Checkouts::Creator` already has the inventory record in hand

`checkout_items` records are kept after confirmation as a historical reference.

---

## Routes

```ruby
resources :checkouts, only: [:index, :show, :new, :create], as: :inventory_checkouts do
  resources :items, only: [:create, :update, :destroy]
end
```

Generated routes:

```
POST   /inventories/checkouts/:checkout_id/items        → Inventories::ItemsController#create
PATCH  /inventories/checkouts/:checkout_id/items/:id    → Inventories::ItemsController#update
DELETE /inventories/checkouts/:checkout_id/items/:id    → Inventories::ItemsController#destroy
```

---

## Controllers

### New: `Inventories::ItemsController`

**`create`**
1. Scope `Client::Inventory` to `current_client`, find by `client_inventory_id` param
2. Find the draft checkout by `params[:checkout_id]` scoped to `current_client`
3. Upsert `CheckoutItem` — increment quantity if the same `client_inventory_id` already exists, otherwise build new
4. Respond via Turbo Stream: update floating basket count badge, flash success inline

**`update`**
- Find item via `params[:id]`, scoped through `current_client`'s draft checkout
- Update quantity; destroy if quantity drops to 0
- Respond via Turbo Stream

**`destroy`**
- Find and destroy item scoped to `current_client`'s draft checkout
- Respond via Turbo Stream: update basket count

### Modified: `CheckoutsController`

**`new`**
- Replace `current_client.checkouts.new` with `current_client.checkouts.find_or_initialize_by(status: :draft)`
- Pre-populates the form with existing draft items

**`create`**
- Delegates to `Checkouts::Creator` — see service changes below

### Modified: `ProductsController#show`

Add one line before render:
```ruby
@draft_checkout = current_client.checkouts.find_or_create_by!(status: :draft, user: current_user)
```
Used by the view to build form action URLs for each variant row.

---

## Service: `Checkouts::Creator` changes

Currently reads `inventory_movements` from nested form params. Updated to:

1. Read `checkout.checkout_items`
2. For each item, create a `Client::InventoryMovement` with `client_inventory_id` and `movement_type: :stock_out`
3. Decrement stock using existing `with_lock` pattern
4. Mark checkout `status: :confirmed`

Stock validation and transaction logic are unchanged — only the data source changes from form params to persisted `checkout_items`.

---

## Views

### `products/_variants_table.html.erb` — two additions per row

Add a **Qty** column with a number input and an **Add to Basket** button. Each row is its own small Turbo-enabled form:

```
| Color | Size | SKU    | Stock | Qty    | Action            |
|-------|------|--------|-------|--------|-------------------|
| Red   | S    | RED-S  | 12    | [ 1 ]  | [+ Add to Basket] |
| Red   | M    | RED-M  | 0     | —      | (out of stock)    |
```

- Rows with `stock == 0`: show "Out of stock", no input, button disabled
- Form POSTs to `inventory_checkout_items_path(@draft_checkout)`
- Hidden field: `client_inventory_id`
- Turbo Stream response: update floating basket badge + inline success flash

### New: `shared/_floating_checkout_basket.html.erb`

Mirrors `shared/_floating_cart.html.erb`. Fixed button bottom-right, shows draft item count badge, links to `new_inventory_checkout_path`. Rendered in the inventory workspace layout. Disappears when draft is empty.

### `checkouts/_form.html.erb` — pre-populated items

Items section renders from `draft.checkout_items` instead of an empty table. Staff can still add more via SKU scan — both paths write to the same draft.

---

## Data Flow

```
Staff opens /inventories/products/:id
  → ProductsController#show finds/creates draft checkout
  → Variants table renders with qty inputs + Add to Basket buttons

Staff types qty, clicks Add to Basket
  → POST /inventories/checkouts/:checkout_id/items
  → CheckoutItem upserted on draft
  → Turbo Stream: basket badge count updates, inline flash

Staff repeats across products/variants
  → All items accumulate in the same draft checkout

Staff clicks floating basket button
  → /inventories/checkouts/new
  → Form pre-loaded with draft items
  → Staff fills in recipient name + email

Staff clicks Create Checkout
  → Checkouts::Creator reads checkout_items
  → Creates inventory_movements, decrements stock
  → Checkout marked confirmed
  → Redirect to checkout show page
```

---

## Out of Scope

- Background job for orphaned draft cleanup (deferred)
- Replacing the existing SKU scan form (it remains as-is)
