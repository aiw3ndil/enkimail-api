class User < ApplicationRecord
  has_secure_password

  has_many :contacts
  has_many :contact_lists
  has_many :campaigns
  has_many :email_templates

  before_create :generate_api_key

  private

  def generate_api_key
    self.api_key = SecureRandom.hex(16)
  end
end
