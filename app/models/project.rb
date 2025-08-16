class Project < ApplicationRecord
  enum :status, {
    draft: 'draft',
    active: 'active',
    archived: 'archived'
  }, prefix: false, default: :draft

  scope :search_by_keyword, ->(keyword) {
    joins(:client)
    .where("#{table_name}.name ILIKE :keyword OR 
            #{Client.table_name}.company_name ILIKE :keyword OR
            #{Client.table_name}.personal_name ILIKE :keyword",
            keyword: "%#{sanitize_sql_like(keyword)}%")
  }

  belongs_to :client

  has_many :orders, dependent: :destroy
  has_many :products_projects, dependent: :destroy
  has_many :products, through: :products_projects

  validates :name, presence: true

  has_rich_text :description
end
