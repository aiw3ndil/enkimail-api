class Campaign < ApplicationRecord
  belongs_to :email_template
  belongs_to :contact_list
  belongs_to :user
  has_many :email_events, dependent: :destroy

  enum status: { draft: 0, scheduled: 1, sending: 2, sent: 3, failed: 4 }

  validates :name, presence: true
  validates :subject, presence: true
  validates :status, presence: true
  validates :email_template, presence: true
  validates :contact_list, presence: true

  validates :scheduled_at, presence: true, if: :scheduled?
  validate :scheduled_at_must_be_in_the_future, if: -> { scheduled_at.present? && scheduled? }

  private

  def scheduled_at_must_be_in_the_future
    if scheduled_at.present? && scheduled_at <= Time.current
      errors.add(:scheduled_at, "must be in the future")
    end
  end
end
