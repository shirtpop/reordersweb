class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable, :trackable

  enum :role, {
    client: "client",
    admin: "admin"
  }, prefix: true

  belongs_to :client, optional: true

  has_many :orders, foreign_key: :ordered_by_id

  validates :role, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :client_id, presence: true, if: -> { role_client? }

  validate :admin_cannot_belong_to_client

  before_create :mark_as_logged_in, if: -> { role_admin? }

  def self.ransackable_attributes(auth_object = nil)
    %w[email sign_in_count]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end

  private

  def admin_cannot_belong_to_client
    if role_admin? && client.present?
      errors.add(:client_id, "cannot be assigned to an admin user")
    end
  end

  def mark_as_logged_in
    self.first_time_login = false
  end
end
