# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  skip_before_action :authenticate_request!

  def index
    total_campaigns = Campaign.count
    total_contacts = Contact.count
    # This is a simplification. A more accurate way would be to count the number of emails actually sent.
    total_sent = Campaign.all.sum { |c| c.contact_list.contacts.count }

    opens = EmailEvent.where(event_type: :open).count
    clicks = EmailEvent.where(event_type: :click).count
    bounces = EmailEvent.where(event_type: :bounce).count
    spam_reports = EmailEvent.where(event_type: :spam_report).count

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
