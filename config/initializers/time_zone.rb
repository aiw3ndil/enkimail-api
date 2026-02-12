# config/initializers/time_zone.rb
Rails.application.config.after_initialize do
  Rails.logger.debug "DEBUG: Time.zone in initializer after_initialize: #{Time.zone.inspect}"
  Rails.logger.debug "DEBUG: config.time_zone in initializer after_initialize: #{Rails.application.config.time_zone.inspect}"
end
