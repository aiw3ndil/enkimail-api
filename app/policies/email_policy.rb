class EmailPolicy < ApplicationPolicy
  def create?
    # For now, let's allow creation if a user is present (authenticated)
    # We will refine this later with actual authentication
    user.present?
  end
end
