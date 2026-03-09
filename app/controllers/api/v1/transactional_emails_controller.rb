module Api
  module V1
    class TransactionalEmailsController < ApplicationController

      def create
        unless params[:to].present? && params[:subject].present? && (params[:body].present? || params[:html_body].present?)
          return render json: { error: 'Missing required parameters: to, subject, and body (or html_body)' }, status: :unprocessable_entity
        end

        unless current_user.can_send_emails?
          return render json: { error: "Daily email limit reached (#{current_user.daily_email_limit} emails/day). Upgrade your plan to increase your limit." }, status: :too_many_requests
        end

        # Validate Sender
        from_email = params[:from]

        if from_email.present?
          sender = current_user.senders.find_by(email: from_email)
          unless sender
            return render json: { error: "Sender '#{from_email}' not found. Please add it to your Senders list first." }, status: :unprocessable_entity
          end
        else
          # Auto-select first verified sender
          sender = current_user.senders.joins(:domain).where(domains: { status: :verified }).first
          
          unless sender
            return render json: { error: "No verified sender found. Please add and verify a Sender identity to send emails." }, status: :unprocessable_entity
          end
          
          from_email = sender.email
        end

        unless sender.domain&.verified?
          return render json: { error: "Domain '#{sender.domain&.name}' is not verified. Please verify SPF/DKIM records." }, status: :unprocessable_entity
        end

        unless sender.domain&.verified?
          return render json: { error: "Domain '#{sender.domain&.name}' is not verified. Please verify SPF/DKIM records." }, status: :unprocessable_entity
        end

        # Find or create contact to ensure tracking works
        contact = current_user.contacts.find_or_create_by!(email: params[:to])

        email_params = {
          to: params[:to],
          subject: params[:subject],
          body: params[:body],
          html_body: params[:html_body],
          from: from_email,
          contact_id: contact.id, # Pass the contact_id for tracking
          user_id: current_user.id
        }

        SendTransactionalEmailJob.perform_now(email_params)

        render json: { message: 'Email queued for sending', status: 'queued' }, status: :accepted
      rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
      end
    end
  end
end
