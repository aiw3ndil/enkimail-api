class TransactionalMailer < ActionMailer::Base
  include TrackingConcern
  layout 'mailer'

  def send_email(to:, subject:, body: nil, html_body: nil, from: nil, contact_id: nil, email_template_id: nil)
    from_address = from || "no-reply@enkimail.com"

    # TrackingConcern will handle the creation of the 'sent' event even if no HTML is present
    # We call add_tracking_to_html regardless of whether we have html_body or body
    # If html_body is nil, add_tracking_to_html will still create the EmailEvent and return nil
    html_body = add_tracking_to_html(html_body, contact_id, nil, email_template_id)

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
