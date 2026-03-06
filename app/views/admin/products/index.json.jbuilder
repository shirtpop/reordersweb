json.products @products do |product|
  json.id product.id
  json.name product.name
  json.price_info product.price_info
  json.color_names product.color_names
end
