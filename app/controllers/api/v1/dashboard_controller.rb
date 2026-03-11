module Api
  module V1
    class DashboardController < ApplicationController
      def index
        # Base query for all user events (campaign and transactional)
        all_events = EmailEvent.joins(:contact).where(contacts: { user_id: current_user.id })
        
        @total_campaigns = current_user.campaigns.count
        @total_contacts = current_user.contacts.count
        # Daily Limits
        daily_current = current_user.daily_email_count
        daily_limit = current_user.daily_email_limit

        # Total lifetime count (Counter Cache)
        transactional_total = current_user.transactional_emails_count

        # Campaign Sent (From campaign events)
        campaign_sent = all_events.where(event_type: :sent).where.not(campaign_id: nil).count

        @total_sent = campaign_sent + transactional_total
        @opens = all_events.where(event_type: :open).count
        @clicks = all_events.where(event_type: :click).count
        @bounces = all_events.where(event_type: :bounce).count
        @spam_reports = all_events.where(event_type: :spam_report).count

        # Calculate rates
        open_rate = @total_sent > 0 ? ((@opens.to_f / @total_sent) * 100) : 0.0
        click_rate = @total_sent > 0 ? ((@clicks.to_f / @total_sent) * 100) : 0.0
        bounce_rate = @total_sent > 0 ? ((@bounces.to_f / @total_sent) * 100) : 0.0
        spam_report_rate = @total_sent > 0 ? ((@spam_reports.to_f / @total_sent) * 100) : 0.0

        # Time series data for charts (last 30 days)
        @time_series = (30.days.ago.to_date..Date.current).map do |date|
          {
            date: date.strftime('%b %d'),
            sent: all_events.where(event_type: :sent, created_at: date.all_day).count,
            opens: all_events.where(event_type: :open, created_at: date.all_day).count,
            clicks: all_events.where(event_type: :click, created_at: date.all_day).count
          }
        end

        render json: {
          user_id: current_user.id,
          user_email: current_user.email,
          total_campaigns: @total_campaigns,
          total_contacts: @total_contacts,
          total_sent: @total_sent,
          breakdown: {
            sent: { 
              total: @total_sent, 
              campaign: campaign_sent, 
              transactional: transactional_total,
              daily_current: daily_current,
              daily_limit: daily_limit
            }
          },
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
          },
          time_series: @time_series
        }
      end
    end
  end
end
