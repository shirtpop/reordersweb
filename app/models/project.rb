class Project < ApplicationRecord
  enum :status, {
    draft: 'draft',
    active: 'active',
    archived: 'archived'
  }, prefix: true

  belongs_to :client

  has_many :products_projects, dependent: :destroy
  has_many :products, through: :products_projects

  validates :name, presence: true

  has_rich_text :description
end
