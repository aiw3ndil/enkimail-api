# app/controllers/api/v1/application_controller.rb
class Api::V1::ApplicationController < ApplicationController
  include Pundit::Authorization

  # Override Pundit's policy_scope to automatically use namespaced policies
  def policy_scope(scope)
    # This will look for Api::V1::ModelPolicy::Scope
    super([:api, :v1, scope])
  end

  # Override Pundit's authorize to automatically use namespaced policies
  def authorize(record, query=nil, policy_class: nil)
    # If policy_class is explicitly provided, use it.
    # Otherwise, infer from Api::V1::ModelPolicy
    if policy_class
      super(record, query, policy_class: policy_class)
    else
      super([:api, :v1, record], query)
    end
  end

  # Helper to generate namespaced URLs
  # This will allow `location: @object` to correctly resolve to `api_v1_object_url`
  # It's crucial for the `location` header in `created` responses.
  def self.inherited(subclass)
    super
    subclass.send(:include, Rails.application.routes.url_helpers)
    subclass.send(:include, Rails.application.routes.mounted_helpers)
  end

  # Ensure polymorphic_url works with namespaced resources
  def default_url_options
    if defined?(super)
      super.merge(only_path: false, host: request.host_with_port)
    else
      { only_path: false, host: request.host_with_port }
    end
  end
end
