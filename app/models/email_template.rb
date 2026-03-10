class EmailTemplate < ApplicationRecord
  belongs_to :user
  has_many :campaigns, dependent: :destroy
  has_many :email_events, dependent: :nullify
end
