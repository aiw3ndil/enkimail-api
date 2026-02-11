class EmailEvent < ApplicationRecord
  belongs_to :contact
  belongs_to :campaign, optional: true
  belongs_to :email_template, optional: true

  enum event_type: { open: 0, click: 1 }

  validates :event_type, presence: true
  validates :contact, presence: true
  validates :url, presence: true, if: -> { click? } # URL is required only for click events
end
