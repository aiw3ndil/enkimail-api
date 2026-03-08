class TransactionalMailer < ActionMailer::Base
  def send_email(to:, subject:, body: nil, html_body: nil, from: nil)
    from_address = from || "no-reply@enkimail.com"

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
