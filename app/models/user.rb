class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, on: :create

  has_many :contacts, dependent: :destroy
  has_many :contact_lists
  has_many :campaigns
  has_many :email_templates
  has_many :webhook_endpoints, dependent: :destroy

  before_create :generate_api_key

  private

  def generate_api_key
    self.api_key = SecureRandom.hex(16)
  end
end
