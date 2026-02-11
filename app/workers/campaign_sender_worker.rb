class CampaignSenderWorker
  include Sidekiq::Worker

  def perform(campaign_id)
    campaign = Campaign.find_by(id: campaign_id)
    return unless campaign&.sent? # Only process if campaign is marked as sent (or processing)

    contact_list = campaign.contact_list
    email_template = campaign.email_template

    # For each contact in the list, enqueue an individual email sending job
    contact_list.contacts.each do |contact|
      # Prepare data for the template interpolation
      data = {
        user_name: contact.first_name || contact.email.split('@').first, # Fallback if no first name
        user_email: contact.email,
        campaign_name: campaign.name,
        # ... any other general campaign/contact specific data
      }.merge(contact.custom_attributes || {}) # Merge custom attributes if present

      EmailSenderWorker.perform_async(
        contact.email, # 'to' address
        email_template.name, # template_name
        data, # data for interpolation
        contact.id, # contact_id for tracking
        campaign.id, # campaign_id for tracking
        email_template.id # email_template_id for tracking
      )
    end
  rescue ActiveRecord::RecordNotFound
    # Log the error, perhaps update campaign status to failed
    Rails.logger.error "CampaignSenderWorker: Campaign with ID #{campaign_id} not found."
    campaign&.update(status: :failed)
  rescue StandardError => e
    Rails.logger.error "CampaignSenderWorker: Error sending campaign #{campaign_id}: #{e.message}"
    campaign&.update(status: :failed)
  end
end
