# Rack middleware that normalizes the HTTP_HOST header when a reverse proxy
# sends duplicate host values separated by a comma
# (e.g. "api.enkimail.com, api.enkimail.com" → "api.enkimail.com").
# This must run before ActionDispatch::HostAuthorization.
class NormalizeHostMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    if (host = env["HTTP_HOST"]) && host.include?(",")
      env["HTTP_HOST"] = host.split(",").first.strip
    end

    @app.call(env)
  end
end
