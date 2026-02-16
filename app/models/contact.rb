class Contact < ApplicationRecord
  belongs_to :user
  has_many :contact_list_memberships, dependent: :destroy
  has_many :contact_lists, through: :contact_list_memberships

  enum status: { subscribed: 0, unsubscribed: 1, bounced: 2, complained: 3 }

  validates :email, presence: true, uniqueness: { scope: :user_id }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, presence: true
end
