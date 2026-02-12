# app/controllers/webhooks/mta_controller.rb
class Webhooks::MtaController < ApplicationController
  skip_before_action :authenticate_request!
  skip_before_action :verify_authenticity_token

  def create
    payload = JSON.parse(request.body.read)
    event_type = payload['event_type']
    email = payload['email']
    details = payload['details']

    contact = Contact.find_by(email: email)

    if contact
      EmailEvent.create!(
        contact: contact,
        event_type: event_type,
        details: details
      )

      case event_type
      when 'bounce'
        contact.update(status: :bounced)
      when 'spam_report'
        contact.update(status: :complained)
      end

      head :ok
    else
      head :not_found
    end
  rescue JSON::ParserError
    head :bad_request
  end
end
