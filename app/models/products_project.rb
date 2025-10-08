class ProductsProject < ApplicationRecord
  belongs_to :product, class_name: "Product"
  belongs_to :project
end
