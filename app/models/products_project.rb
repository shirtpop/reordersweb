class ProductsProject < ApplicationRecord
  belongs_to :product
  belongs_to :project
end
