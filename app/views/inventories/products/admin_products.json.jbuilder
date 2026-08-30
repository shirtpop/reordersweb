json.products @products do |product|
  json.id product.id
  json.name product.name
  json.description product.description.body
end
