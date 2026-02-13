class Sender < ApplicationRecord
  belongs_to :user
  belongs_to :domain

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: { scope: :user_id, message: "already exists" }
  validate :domain_must_belong_to_user
  validate :email_must_match_domain
  validate :check_sender_limit, on: :create

  private

  def domain_must_belong_to_user
    if domain.present? && domain.user_id != user_id
      errors.add(:domain, "must belong to you")
    end
  end

  def email_must_match_domain
    if email.present? && domain.present?
      unless email.ends_with?("@#{domain.name}")
        errors.add(:email, "must match the selected domain (#{domain.name})")
      end
    end
  end

  def check_sender_limit
    limit = user.pro? ? 15 : 1
    if user.senders.count >= limit
      errors.add(:base, "#{user.role.capitalize} plan is limited to #{limit} Sender identity(ies). Upgrade to Pro to add more.")
    end
  end
end
