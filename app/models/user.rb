class User < ApplicationRecord
  has_secure_password

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, presence: true, length: { minimum: 6 }, on: :create
  
  enum role: { standard: 0, pro: 1 }

  after_initialize :set_default_role, if: :new_record?

  def set_default_role
    self.role ||= :standard
  end

  def daily_email_limit
    pro? ? 1000 : 300
  end

  def can_send_emails?
    daily_email_count < daily_email_limit
  end

  def daily_email_count
    # Count sent emails in the last 24 hours
    EmailEvent.where(contact_id: contacts.select(:id), event_type: :sent, created_at: 1.day.ago..Time.current).count
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end

  has_many :contacts, dependent: :destroy
  has_many :contact_lists
  has_many :campaigns
  has_many :email_templates
  has_many :webhook_endpoints, dependent: :destroy
  has_many :domains, dependent: :destroy
  has_many :senders, dependent: :destroy

  before_create :generate_api_key

  private

  def generate_api_key
    self.api_key = SecureRandom.hex(16)
  end
end
