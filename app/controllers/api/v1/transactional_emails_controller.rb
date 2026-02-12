module Api
  module V1
    class TransactionalEmailsController < ApplicationController

      def create
        unless params[:to].present? && params[:subject].present? && (params[:body].present? || params[:html_body].present?)
          return render json: { error: 'Missing required parameters: to, subject, and body (or html_body)' }, status: :unprocessable_entity
        end

        email_params = {
          to: params[:to],
          subject: params[:subject],
          body: params[:body],
          html_body: params[:html_body],
          from: params[:from]
        }

        SendTransactionalEmailJob.perform_later(email_params)

        render json: { message: 'Email queued for sending', status: 'queued' }, status: :accepted
      rescue StandardError => e
        render json: { error: e.message }, status: :internal_server_error
      end
    end
  end
end
