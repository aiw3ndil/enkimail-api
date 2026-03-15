require "active_support/core_ext/integer/time"

Rails.application.configure do
  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local = false

  # Store uploaded files on the local file system.
  config.active_storage.service = :local

  # Force all access to the app over SSL.
  config.force_ssl = true

  # Log to STDOUT by default.
  config.logger = ActiveSupport::Logger.new(STDOUT)
    .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
    .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

  # Prepend all log lines with the following tags.
  config.log_tags = [ :request_id ]

  # Log level.
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Mailer settings.
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true

  config.action_mailer.smtp_settings = {
    address:              "postfix",
    port:                 25,
    domain:               "mail.enkimail.com",
    authentication:       nil,
    enable_starttls_auto: false,
    openssl_verify_mode:  'none',
    open_timeout:         5,
    read_timeout:         5
  }

  config.action_mailer.default_url_options = { host: 'api.enkimail.com', protocol: 'https' }

  # Enable locale fallbacks for I18n.
  config.i18n.fallbacks = true

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # ---------------------------------------------------------------------------
  # HOST AUTHORIZATION - DEBUG & CLEAR
  # ---------------------------------------------------------------------------
  # Clear existing hosts and allow everything via regex to handle doubled headers.
  config.hosts.clear
  config.hosts << /.*/
  
  puts "RAILS_PRODUCTION_LOG: config.hosts cleared and set to /.*/"

  # Skip host authorization for health check endpoint.
  config.host_authorization = { exclude: ->(request) { request.path == "/up" } }
end
