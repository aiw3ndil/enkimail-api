class Api::V1::ContactListPolicy < Api::V1::ApplicationPolicy
  def index?
    true # All authenticated users can view the index, scope will filter
  end

  def show?
    record.user_id == user.id
  end

  def create?
    user.present?
  end

  def update?
    record.user_id == user.id
  end

  def destroy?
    record.user_id == user.id
  end

  def add_contact?
    record.user_id == user.id
  end

  def remove_contact?
    record.user_id == user.id
  end

  class Scope < Scope
    def resolve
      scope.where(user_id: user.id)
    end
  end
end
