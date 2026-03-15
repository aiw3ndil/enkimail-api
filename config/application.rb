require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module EnkimailApi
  # Middleware to clean duplicated Host headers sent by reverse proxies like Coolify/Traefik.
  # Normalizes both HTTP_HOST and HTTP_X_FORWARDED_HOST headers.
  class NormalizeHostMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      # Normalize HTTP_HOST (e.g. "api.enkimail.com, api.enkimail.com" -> "api.enkimail.com")
      if env["HTTP_HOST"]&.include?(",")
        env["HTTP_HOST"] = env["HTTP_HOST"].split(",").first.strip
      end

      # Normalize X-Forwarded-Host sent by proxies
      if env["HTTP_X_FORWARDED_HOST"]&.include?(",")
        env["HTTP_X_FORWARDED_HOST"] = env["HTTP_X_FORWARDED_HOST"].split(",").first.strip
      end

      @app.call(env)
    end
  end

  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    config.autoload_lib(ignore: %w(assets tasks))

    config.time_zone = "Europe/Helsinki"

    config.api_only = true
    config.active_job.queue_adapter = :sidekiq
    config.active_record.default_timezone = :utc

    # Insertamos el middleware al principio de la pila para limpiar el host antes de validarlo
    config.middleware.insert_before 0, NormalizeHostMiddleware
  end
end
