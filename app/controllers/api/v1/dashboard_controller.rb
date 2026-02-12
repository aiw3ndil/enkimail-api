module Api
  module V1
    class DashboardController < ApplicationController
      def index
        # Scope data to current_user
        # We need to join campaigns to ensure we only get events for the current user's campaigns
        # or use a direct association if one exists. 
        # Since EmailEvent belongs to Campaign, and Campaign belongs to User, we can do:
        
        email_events = EmailEvent.joins(:campaign).where(campaigns: { user_id: current_user.id })
        
        @total_campaigns = current_user.campaigns.count
        @total_contacts = current_user.contacts.count
        
        @total_sent = email_events.where(event_type: :sent).count
        @opens = email_events.where(event_type: :open).count
        @clicks = email_events.where(event_type: :click).count
        @bounces = email_events.where(event_type: :bounce).count
        @spam_reports = email_events.where(event_type: :spam_report).count

        # Calculate rates
        open_rate = @total_sent > 0 ? (@opens.to_f / @total_sent * 100).round(2) : 0.0
        click_rate = @total_sent > 0 ? (@clicks.to_f / @total_sent * 100).round(2) : 0.0
        bounce_rate = @total_sent > 0 ? (@bounces.to_f / @total_sent * 100).round(2) : 0.0
        spam_report_rate = @total_sent > 0 ? (@spam_reports.to_f / @total_sent * 100).round(2) : 0.0

        render json: {
          total_campaigns: @total_campaigns,
          total_contacts: @total_contacts,
          total_sent: @total_sent,
          rates: {
            open_rate: open_rate,
            click_rate: click_rate,
            bounce_rate: bounce_rate,
            spam_report_rate: spam_report_rate
          },
          events: {
            opens: @opens,
            clicks: @clicks,
            bounces: @bounces,
            spam_reports: @spam_reports
          }
        }
      end
    end
  end
end
