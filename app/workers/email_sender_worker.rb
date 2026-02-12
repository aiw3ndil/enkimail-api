class EmailSenderWorker
  include Sidekiq::Worker

  def perform(to, template_name, data, contact_id, campaign_id = nil, email_template_id = nil)
    UserMailer.send_generic_email(to, template_name, contact_id, data, campaign_id, email_template_id).deliver_now
  end
end
