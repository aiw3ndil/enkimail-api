class CampaignSenderJob < ApplicationJob
  queue_as :default

  def perform(campaign_id)
    campaign = Campaign.find_by(id: campaign_id)
    return unless campaign

    contact_list = campaign.contact_list
    email_template = campaign.email_template

    # For each contact in the list, enqueue an individual email sending job
    contact_list.contacts.each do |contact|
      # Prepare data for the template interpolation
      data = {
        user_name: contact.first_name || contact.email.split('@').first,
        user_email: contact.email,
        campaign_name: campaign.name,
      }.merge(contact.custom_attributes || {}).transform_keys(&:to_s)

      SendCampaignEmailJob.perform_later(
        contact.email,
        email_template.name,
        data,
        contact.id,
        campaign.id,
        email_template.id
      )
    end
    campaign.update(status: :sent)
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error "CampaignSenderJob: Campaign with ID #{campaign_id} not found."
    campaign&.update(status: :failed)
  rescue StandardError => e
    Rails.logger.error "CampaignSenderJob: Error sending campaign #{campaign_id}: #{e.message}"
    campaign&.update(status: :failed)
  end
end
