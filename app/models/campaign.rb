class Campaign < ApplicationRecord
  belongs_to :email_template
  belongs_to :contact_list
  belongs_to :user

  enum status: { draft: 0, sent: 1, failed: 2 }

  validates :name, presence: true
  validates :subject, presence: true
  validates :status, presence: true
  validates :email_template, presence: true
  validates :contact_list, presence: true
end
