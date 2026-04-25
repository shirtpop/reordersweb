# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_04_23_141037) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.string "name", null: false
    t.text "body"
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "addresses", force: :cascade do |t|
    t.string "street"
    t.string "city"
    t.string "state"
    t.string "zip_code"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "catalogs", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.string "name", null: false
    t.string "status", limit: 10, default: "draft", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_catalogs_on_client_id"
  end

  create_table "catalogs_products", id: false, force: :cascade do |t|
    t.bigint "catalog_id", null: false
    t.bigint "product_id", null: false
    t.index ["catalog_id", "product_id"], name: "index_catalogs_products_on_catalog_id_and_product_id", unique: true
  end

  create_table "client_checkouts", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "user_id", null: false
    t.string "recipient_email"
    t.string "recipient_first_name"
    t.string "recipient_last_name"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_client_checkouts_on_client_id"
    t.index ["user_id"], name: "index_client_checkouts_on_user_id"
  end

  create_table "client_inventories", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "client_product_variant_id", null: false
    t.integer "quantity", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "client_product_variant_id"], name: "index_client_inventories_on_client_and_variant", unique: true
    t.index ["client_id"], name: "index_client_inventories_on_client_id"
    t.index ["client_product_variant_id"], name: "index_client_inventories_on_client_product_variant_id"
  end

  create_table "client_inventory_movements", force: :cascade do |t|
    t.bigint "client_inventory_id", null: false
    t.bigint "order_item_id"
    t.bigint "user_id"
    t.string "movement_type", limit: 20, default: "in", null: false
    t.integer "quantity", null: false
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "client_checkout_id"
    t.index ["client_checkout_id"], name: "index_client_inventory_movements_on_client_checkout_id"
    t.index ["client_inventory_id"], name: "index_client_inventory_movements_on_client_inventory_id"
    t.index ["movement_type"], name: "index_client_inventory_movements_on_movement_type"
    t.index ["order_item_id"], name: "index_client_inventory_movements_on_order_item_id"
    t.index ["user_id"], name: "index_client_inventory_movements_on_user_id"
  end

  create_table "client_product_variants", force: :cascade do |t|
    t.bigint "client_product_id", null: false
    t.string "color", limit: 70
    t.string "size", limit: 30
    t.string "sku"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_product_id"], name: "index_client_product_variants_on_client_product_id"
    t.index ["sku"], name: "index_client_product_variants_on_sku", unique: true
  end

  create_table "client_products", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "product_id"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "product_variants_count", default: 0
    t.index ["client_id"], name: "index_client_products_on_client_id"
    t.index ["product_id"], name: "index_client_products_on_product_id"
  end

  create_table "clients", force: :cascade do |t|
    t.string "company_name"
    t.string "personal_name"
    t.string "phone_number"
    t.bigint "address_id"
    t.bigint "shipping_address_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "company_url"
    t.boolean "inventory_enabled", default: false
    t.index ["address_id"], name: "index_clients_on_address_id"
    t.index ["company_name"], name: "index_clients_on_company_name"
    t.index ["personal_name"], name: "index_clients_on_personal_name"
    t.index ["shipping_address_id"], name: "index_clients_on_shipping_address_id"
  end

  create_table "drive_files", force: :cascade do |t|
    t.string "attachable_type"
    t.bigint "attachable_id"
    t.string "drive_file_id"
    t.string "mime_type"
    t.string "filename"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attachable_type", "attachable_id"], name: "index_drive_files_on_attachable"
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.string "color", null: false
    t.string "size", null: false
    t.integer "quantity", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "product_color_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_color_id"], name: "index_order_items_on_product_color_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "client_id"
    t.bigint "catalog_id"
    t.date "delivery_date"
    t.decimal "price", precision: 10, scale: 2, default: "0.0"
    t.integer "total_quantity", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "ordered_by_id"
    t.bigint "shipped_to_id"
    t.datetime "received_at"
    t.bigint "received_by_id"
    t.string "status", default: "cart", null: false
    t.datetime "submitted_at"
    t.string "order_number", null: false
    t.index ["catalog_id"], name: "index_orders_on_catalog_id"
    t.index ["client_id"], name: "index_orders_on_client_id"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["ordered_by_id"], name: "index_orders_on_ordered_by_id"
    t.index ["received_by_id"], name: "index_orders_on_received_by_id"
    t.index ["shipped_to_id"], name: "index_orders_on_shipped_to_id"
    t.index ["status", "submitted_at"], name: "index_orders_on_status_and_submitted_at"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["submitted_at", "status"], name: "index_orders_on_submitted_at_and_status"
    t.index ["submitted_at"], name: "index_orders_on_submitted_at"
  end

  create_table "product_color_images", force: :cascade do |t|
    t.bigint "product_color_id", null: false
    t.string "angle", limit: 5, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_color_id", "angle"], name: "index_product_color_images_on_product_color_id_and_angle", unique: true
    t.index ["product_color_id"], name: "index_product_color_images_on_product_color_id"
  end

  create_table "product_colors", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.string "name", null: false
    t.string "hex_color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "minimum_order", default: 0, null: false
    t.index ["product_id"], name: "index_product_colors_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name", null: false
    t.jsonb "price_info", default: {}
    t.string "sizes", default: [], array: true
    t.jsonb "colors", default: []
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_products_on_name"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "role", limit: 10, default: "client", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "client_id"
    t.boolean "first_time_login", default: true
    t.index ["client_id"], name: "index_users_on_client_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "catalogs", "clients"
  add_foreign_key "client_checkouts", "clients"
  add_foreign_key "client_checkouts", "users"
  add_foreign_key "client_inventories", "client_product_variants"
  add_foreign_key "client_inventories", "clients"
  add_foreign_key "client_inventory_movements", "client_checkouts"
  add_foreign_key "client_inventory_movements", "client_inventories"
  add_foreign_key "client_inventory_movements", "order_items"
  add_foreign_key "client_inventory_movements", "users"
  add_foreign_key "client_product_variants", "client_products"
  add_foreign_key "client_products", "clients"
  add_foreign_key "client_products", "products"
  add_foreign_key "clients", "addresses"
  add_foreign_key "clients", "addresses", column: "shipping_address_id"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "product_colors"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "addresses", column: "shipped_to_id"
  add_foreign_key "orders", "catalogs"
  add_foreign_key "orders", "clients"
  add_foreign_key "orders", "users", column: "ordered_by_id"
  add_foreign_key "orders", "users", column: "received_by_id"
  add_foreign_key "product_color_images", "product_colors"
  add_foreign_key "product_colors", "products"
  add_foreign_key "users", "clients"
end
