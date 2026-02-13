class WebhookDispatcherJob < ApplicationJob
  queue_as :default

  def perform(webhook_endpoint_id, event_data)
    endpoint = WebhookEndpoint.find_by(id: webhook_endpoint_id)
    return unless endpoint&.active?

    uri = URI.parse(endpoint.url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    
    request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
    request.body = event_data.to_json

    # Add signature
    timestamp = Time.now.to_i
    signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), endpoint.secret, "#{timestamp}.#{request.body}")
    request['X-EnkiMail-Signature'] = "t=#{timestamp},v1=#{signature}"

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      # Retries are handled by Sidekiq automatically if we raise an error
      raise "Webhook failed with status #{response.code}"
    end
  rescue StandardError => e
    Rails.logger.error("WebhookDispatcherJob failed for endpoint #{endpoint.id}: #{e.message}")
    raise e # Re-raise to trigger retry
  end
end
