json.id @product_variant.id
json.sku @product_variant.sku
json.color @product_variant.color
json.size @product_variant.size
json.product_name @product_variant.client_product.name
json.inventory_id @product_variant.inventory&.id
json.quantity @product_variant.inventory&.quantity || 0
