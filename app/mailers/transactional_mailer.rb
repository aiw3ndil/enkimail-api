class TransactionalMailer < ActionMailer::Base
  include TrackingConcern
  layout 'mailer'

  def send_email(to:, subject:, body: nil, html_body: nil, from: nil, contact_id: nil, email_template_id: nil)
    from_address = from || "no-reply@enkimail.com"

    if html_body.present? && contact_id.present?
      html_body = add_tracking_to_html(html_body, contact_id, nil, email_template_id)
    elsif contact_id.present?
      # Even for plain text, we create a sent event if tracking is requested
      EmailEvent.create!(
        event_type: :sent,
        contact_id: contact_id,
        email_template_id: email_template_id
      )
    end

    if html_body.present?
      mail(
        to: to,
        subject: subject,
        from: from_address,
        content_type: "text/html",
        body: html_body
      )
    else
      mail(
        to: to,
        subject: subject,
        from: from_address,
        content_type: "text/plain",
        body: body
      )
    end
  end
end
