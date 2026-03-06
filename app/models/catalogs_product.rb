class CatalogsProduct < ApplicationRecord
  belongs_to :product, class_name: "Product"
  belongs_to :catalog
end
