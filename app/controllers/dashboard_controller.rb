# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  def index
    total_campaigns = current_user.campaigns.count
    total_contacts = current_user.contacts.count
    total_sent = EmailEvent.where(contact_id: current_user.contact_ids, event_type: :sent).count

    opens = EmailEvent.where(contact_id: current_user.contact_ids, event_type: :open).count
    clicks = EmailEvent.where(contact_id: current_user.contact_ids, event_type: :click).count
    bounces = EmailEvent.where(contact_id: current_user.contact_ids, event_type: :bounce).count
    spam_reports = EmailEvent.where(contact_id: current_user.contact_ids, event_type: :spam_report).count

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
