class EmailEvent < ApplicationRecord
  belongs_to :contact
  belongs_to :campaign, optional: true
  belongs_to :email_template, optional: true

  enum event_type: { sent: 0, open: 1, click: 2, bounce: 3, spam_report: 4 }

  validates :event_type, presence: true
  validates :contact, presence: true
  validates :url, presence: true, if: -> { click? } # URL is required only for click events

  after_create_commit :dispatch_webhook

  private

  def dispatch_webhook
    # Find active webhook endpoints for this user that obtain this event type
    user = contact.user
    return unless user

    user.webhook_endpoints.where(active: true).find_each do |endpoint|
      if endpoint.subscribed?(event_type)
        WebhookDispatcherJob.perform_later(endpoint.id, as_payload)
      end
    end
  end

  def as_payload
    {
      event: event_type,
      timestamp: timestamp.to_i,
      email: contact.email,
      campaign_id: campaign_id,
      template_id: email_template_id,
      url: url,
      ip: ip_address,
      user_agent: user_agent,
      details: details
    }
  end
end
