class TransactionalMailer < ApplicationMailer
  layout false

  def send_email(to:, subject:, body: nil, html_body: nil, from: nil)
    from_address = from || default_params[:from]

    if html_body.present?
      mail(to: to, subject: subject, from: from_address) do |format|
        format.html { render inline: html_body }
        format.text { render plain: body } if body.present?
      end
    else
      mail(to: to, subject: subject, from: from_address) do |format|
        format.text { render plain: body }
      end
    end
  end
end
