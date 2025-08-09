class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, 
         :recoverable, :rememberable, :validatable, :trackable

  enum :role, {
    client: 'client',
    admin: 'admin'
  }, prefix: false

  validates :role, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def self.ransackable_attributes(auth_object = nil)
    %w[email sign_in_count]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
