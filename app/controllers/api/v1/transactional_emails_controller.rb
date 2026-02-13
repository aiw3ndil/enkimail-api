module Api
  module V1
    class TransactionalEmailsController < ApplicationController

      def create
        unless params[:to].present? && params[:subject].present? && (params[:body].present? || params[:html_body].present?)
          return render json: { error: 'Missing required parameters: to, subject, and body (or html_body)' }, status: :unprocessable_entity
        end

        unless @current_user.can_send_emails?
          return render json: { error: "Daily email limit reached (#{@current_user.daily_email_limit} emails/day). Upgrade your plan to increase your limit." }, status: :too_many_requests
        end

        # Validate Sender
        from_email = params[:from] || @current_user.email # Fallback to user email if not provided? Or system default? 
        # Actually user email might not be verified. Let's enforce param or use a default verified one if exists?
        # The prompt says: "When a user wants to send a campaign... Is the Sender existing?"
        
        unless from_email.present?
           return render json: { error: 'Missing required parameter: from' }, status: :unprocessable_entity
        end

        sender = @current_user.senders.find_by(email: from_email)
        
        unless sender
          return render json: { error: "Sender '#{from_email}' not found. Please add it to your Senders list first." }, status: :unprocessable_entity
        end

        unless sender.domain&.verified?
          return render json: { error: "Domain '#{sender.domain&.name}' is not verified. Please verify SPF/DKIM records." }, status: :unprocessable_entity
        end

        email_params = {
          to: params[:to],
          subject: params[:subject],
          body: params[:body],
          html_body: params[:html_body],
          from: from_email
        }

        email_params[:user_id] = @current_user.id
        SendTransactionalEmailJob.perform_later(email_params)

        render json: { message: 'Email queued for sending', status: 'queued' }, status: :accepted
      rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
      end
    end
  end
end
