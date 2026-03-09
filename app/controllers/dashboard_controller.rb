# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  def index
    total_campaigns = current_user.campaigns.count
    total_contacts = current_user.contacts.count
    
    # Base query for all user events using a join with contacts
    all_events = EmailEvent.joins(:contact).where(contacts: { user_id: current_user.id })

    # Sent Breakdown
    sent_events = all_events.where(event_type: :sent)
    
    # Use the counter cache for transactional_sent (very fast!)
    transactional_sent = current_user.transactional_emails_count
    
    # Campaign sent is the total minus the transactional count
    total_sent = sent_events.count
    campaign_sent = total_sent - transactional_sent

    # Opens Breakdown
    open_events = all_events.where(event_type: :open)
    total_opens = open_events.count
    transactional_opens = open_events.where("campaign_id IS NULL").count
    campaign_opens = total_opens - transactional_opens
    
    # Clicks Breakdown (excluding placeholder events without user_agent)
    click_events = all_events.where(event_type: :click).where.not(user_agent: nil)
    total_clicks = click_events.count
    transactional_clicks = click_events.where("campaign_id IS NULL").count
    campaign_clicks = total_clicks - transactional_clicks
                       
    # Bounces Breakdown
    bounce_events = all_events.where(event_type: :bounce)
    total_bounces = bounce_events.count
    transactional_bounces = bounce_events.where("campaign_id IS NULL").count
    campaign_bounces = total_bounces - transactional_bounces

    # Spam Reports Breakdown
    spam_events = all_events.where(event_type: :spam_report)
    total_spam = spam_events.count
    transactional_spam = spam_events.where("campaign_id IS NULL").count
    campaign_spam = total_spam - transactional_spam

    render json: {
      user_id: current_user.id,
      user_email: current_user.email,
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
