json.array! @products do |product|
  json.id product.id
  json.name product.name
  json.variant_count product.product_variants.count
  json.variants product.product_variants do |variant|
    json.id variant.id
    json.color variant.color
    json.size variant.size
    json.sku variant.sku
  end
end
