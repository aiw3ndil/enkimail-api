require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module EnkimailApi
  # Middleware para limpiar cabeceras Host duplicadas (común en proxies como Coolify/Traefik)
  class NormalizeHostMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      if env["HTTP_HOST"] && env["HTTP_HOST"].include?(",")
        # Si hay "host1, host1", nos quedamos solo con el primero
        env["HTTP_HOST"] = env["HTTP_HOST"].split(",").first.strip
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
