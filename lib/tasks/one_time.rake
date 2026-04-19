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
