namespace :orders do
  desc "One-time: merge duplicate in_cart orders per user+client into one. Keeps the most recently updated cart, moves items from duplicates, then destroys them. Safe to re-run."
  task merge_duplicate_carts: :environment do
    groups = Order.status_cart
                  .select(:client_id, :ordered_by_id)
                  .group(:client_id, :ordered_by_id)
                  .having("COUNT(*) > 1")

    puts "Found #{groups.length} user+client combo(s) with duplicate carts."

    merged_groups = 0
    deleted       = 0
    errors        = 0

    groups.each do |combo|
      orders = Order.status_cart
                    .where(client_id: combo.client_id, ordered_by_id: combo.ordered_by_id)
                    .order(updated_at: :desc)

      keeper  = orders.first
      extras  = orders[1..]

      puts "  Client ##{combo.client_id} / User ##{combo.ordered_by_id}: keeping Order ##{keeper.id}, merging #{extras.count} duplicate(s)."

      extras.each do |dup|
        ActiveRecord::Base.transaction do
          dup.order_items.each do |item|
            existing = keeper.order_items.find_by(
              product_id: item.product_id,
              color:      item.color,
              size:       item.size
            )

            if existing
              existing.update_columns(quantity: existing.quantity + item.quantity)
              puts "    [MERGE] item product=##{item.product_id} #{item.color}/#{item.size} qty #{item.quantity} added to existing qty #{existing.quantity - item.quantity}"
            else
              item.update_columns(order_id: keeper.id)
              puts "    [MOVE]  item ##{item.id} product=##{item.product_id} #{item.color}/#{item.size} moved to keeper"
            end
          end

          dup.reload.destroy!
          puts "    [DEL]   Order ##{dup.id} destroyed."
          deleted += 1
        end
      rescue => e
        puts "    [ERROR] Order ##{dup.id} — #{e.message}"
        errors += 1
      end

      merged_groups += 1
    end

    puts ""
    puts "Done. Groups processed: #{merged_groups} | Duplicates deleted: #{deleted} | Errors: #{errors}"
  end
end

namespace :order_items do
  desc "One-time migration: set product_color_id on order_items by matching color name against product_colors. Safe to re-run (skips items that already have product_color_id)."
  task backfill_product_color: :environment do
    items = OrderItem.where(product_color_id: nil)

    puts "Found #{items.count} order item(s) without product_color_id."

    updated = 0
    skipped = 0
    errors  = 0

    items.find_each do |item|
      color = ProductColor.find_by(product_id: item.product_id, name: item.color)

      if color.nil?
        puts "  [SKIP] OrderItem ##{item.id} — no ProductColor found for product ##{item.product_id} color \"#{item.color}\""
        skipped += 1
        next
      end

      item.update_columns(product_color_id: color.id)
      puts "  [OK]   OrderItem ##{item.id} — set product_color_id=#{color.id} (\"#{color.name}\")"
      updated += 1
    rescue => e
      puts "  [ERROR] OrderItem ##{item.id} — #{e.message}"
      errors += 1
    end

    puts ""
    puts "Done. Updated: #{updated} | Skipped: #{skipped} | Errors: #{errors}"
  end
end

namespace :products do
  desc "One-time migration: copy JSONB colors column into product_colors table. Safe to re-run (skips products that already have product_colors)."
  task migrate_colors: :environment do
    products = Product.where.not(colors: [ nil, [], "{}" ])

    puts "Found #{products.count} product(s) with JSONB colors to migrate."

    migrated = 0
    skipped  = 0
    errors   = 0

    products.find_each do |product|
      if product.product_colors.exists?
        puts "  [SKIP] Product ##{product.id} \"#{product.name}\" already has #{product.product_colors.count} color(s)."
        skipped += 1
        next
      end

      colors = Array(product.colors).compact

      if colors.empty?
        puts "  [SKIP] Product ##{product.id} \"#{product.name}\" has empty colors array."
        skipped += 1
        next
      end

      ActiveRecord::Base.transaction do
        colors.each_with_index do |color, idx|
          hex = color["hex_color"].presence || color["hex"].presence

          ProductColor.create!(
            product:   product,
            name:      color["name"].to_s.strip,
            hex_color: hex.to_s.strip
          )
        end
      end

      puts "  [OK]   Product ##{product.id} \"#{product.name}\" — migrated #{colors.size} color(s)."
      migrated += 1
    rescue => e
      puts "  [ERROR] Product ##{product.id} \"#{product.name}\" — #{e.message}"
      errors += 1
    end

    puts ""
    puts "Done. Migrated: #{migrated} | Skipped: #{skipped} | Errors: #{errors}"
  end
end
