class WebhookEndpoint < ApplicationRecord
  belongs_to :user

  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }
  validates :events, presence: true

  before_create :generate_secret

  # Event types that can be subscribed to
  EVENTS = %w[sent open click bounce spam_report].freeze

  def subscribed?(event_type)
    events.include?(event_type.to_s)
  end

  private

  def generate_secret
    self.secret ||= SecureRandom.hex(20)
  end
end
