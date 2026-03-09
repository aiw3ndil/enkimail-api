# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  def index
    total_campaigns = current_user.campaigns.count
    total_contacts = current_user.contacts.count
    
    # We use contact_ids to filter events belonging to this user's contacts
    contact_ids = current_user.contact_ids

    total_sent = EmailEvent.where(contact_id: contact_ids, event_type: :sent).count
    opens = EmailEvent.where(contact_id: contact_ids, event_type: :open).count
    
    # Clicks should only count if they have a user_agent, to exclude placeholder click events
    clicks = EmailEvent.where(contact_id: contact_ids, event_type: :click)
                       .where.not(user_agent: nil).count
                       
    bounces = EmailEvent.where(contact_id: contact_ids, event_type: :bounce).count
    spam_reports = EmailEvent.where(contact_id: contact_ids, event_type: :spam_report).count

    render json: {
      total_campaigns: total_campaigns,
      total_contacts: total_contacts,
      total_sent: total_sent,
      events: {
        opens: opens,
        clicks: clicks,
        bounces: bounces,
        spam_reports: spam_reports
      },
      rates: {
        open_rate: total_sent > 0 ? (opens.to_f / total_sent) : 0,
        click_rate: total_sent > 0 ? (clicks.to_f / total_sent) : 0,
        bounce_rate: total_sent > 0 ? (bounces.to_f / total_sent) : 0,
        spam_report_rate: total_sent > 0 ? (spam_reports.to_f / total_sent) : 0
      }
    }
  end
end
