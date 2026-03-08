class TransactionalMailer < ApplicationMailer
  def send_email(to:, subject:, body: nil, html_body: nil, from: nil)
    from_address = from || default_params[:from]

    if html_body.present? && body.present?
      mail(to: to, subject: subject, from: from_address) do |format|
        format.text { render plain: body }
        format.html { render inline: html_body, layout: false }
      end
    elsif html_body.present?
      mail(to: to, subject: subject, from: from_address, content_type: "text/html", body: html_body)
    else
      mail(to: to, subject: subject, from: from_address, content_type: "text/plain", body: body)
    end
  end
end
