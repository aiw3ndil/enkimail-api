class SendTransactionalEmailJob < ApplicationJob
  queue_as :default

  def perform(email_params)
    # email_params should be a hash with keys: 'to', 'subject', 'body', 'html_body', 'from', 'user_id', 'email_template_id'
    
    to = email_params['to'] || email_params[:to]
    subject = email_params['subject'] || email_params[:subject]
    body = email_params['body'] || email_params[:body]
    html_body = email_params['html_body'] || email_params[:html_body]
    from = email_params['from'] || email_params[:from]
    user_id = email_params['user_id'] || email_params[:user_id]
    email_template_id = email_params['email_template_id'] || email_params[:email_template_id]

    user = User.find_by(id: user_id)
    return unless user

    contact = Contact.find_or_create_by(email: to, user: user)

    # The mailer now handles creating the 'sent' event and adding tracking
    TransactionalMailer.send_email(
      to: to,
      subject: subject,
      body: body,
      html_body: html_body,
      from: from,
      contact_id: contact.id,
      email_template_id: email_template_id
    ).deliver_now
  end
end
