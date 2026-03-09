# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  def index
    total_campaigns = current_user.campaigns.count
    total_contacts = current_user.contacts.count
    
    # We use contact_ids to filter events belonging to this user's contacts
    contact_ids = current_user.contact_ids

    # Base query for all user events
    all_events = EmailEvent.where(contact_id: contact_ids)

    # Sent Breakdown
    sent_events = all_events.where(event_type: :sent)
    total_sent = sent_events.count
    campaign_sent = sent_events.where.not(campaign_id: nil).count
    transactional_sent = sent_events.where(campaign_id: nil).count

    # Opens Breakdown
    open_events = all_events.where(event_type: :open)
    total_opens = open_events.count
    campaign_opens = open_events.where.not(campaign_id: nil).count
    transactional_opens = open_events.where(campaign_id: nil).count
    
    # Clicks Breakdown (excluding placeholder events without user_agent)
    click_events = all_events.where(event_type: :click).where.not(user_agent: nil)
    total_clicks = click_events.count
    campaign_clicks = click_events.where.not(campaign_id: nil).count
    transactional_clicks = click_events.where(campaign_id: nil).count
                       
    # Bounces Breakdown
    bounce_events = all_events.where(event_type: :bounce)
    total_bounces = bounce_events.count
    campaign_bounces = bounce_events.where.not(campaign_id: nil).count
    transactional_bounces = bounce_events.where(campaign_id: nil).count

    # Spam Reports Breakdown
    spam_events = all_events.where(event_type: :spam_report)
    total_spam = spam_events.count
    campaign_spam = spam_events.where.not(campaign_id: nil).count
    transactional_spam = spam_events.where(campaign_id: nil).count

    render json: {
      total_campaigns: total_campaigns,
      total_contacts: total_contacts,
      total_sent: total_sent,
      breakdown: {
        sent: { total: total_sent, campaign: campaign_sent, transactional: transactional_sent },
        opens: { total: total_opens, campaign: campaign_opens, transactional: transactional_opens },
        clicks: { total: total_clicks, campaign: campaign_clicks, transactional: transactional_clicks },
        bounces: { total: total_bounces, campaign: campaign_bounces, transactional: transactional_bounces },
        spam_reports: { total: total_spam, campaign: campaign_spam, transactional: transactional_spam }
      },
      rates: {
        open_rate: total_sent > 0 ? (total_opens.to_f / total_sent) : 0,
        click_rate: total_sent > 0 ? (total_clicks.to_f / total_sent) : 0,
        bounce_rate: total_sent > 0 ? (total_bounces.to_f / total_sent) : 0,
        spam_report_rate: total_sent > 0 ? (total_spam.to_f / total_sent) : 0
      }
    }
  end
end
