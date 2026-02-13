module Api
  module V1
    class WebhookEndpointsController < ApplicationController
      before_action :ensure_pro_user
      before_action :set_webhook_endpoint, only: [:show, :update, :destroy]

      def index
        render json: @current_user.webhook_endpoints
      end

      def show
        render json: @webhook_endpoint
      end

      def create
        @webhook_endpoint = @current_user.webhook_endpoints.build(webhook_endpoint_params)

        if @webhook_endpoint.save
          render json: @webhook_endpoint, status: :created
        else
          render json: { errors: @webhook_endpoint.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @webhook_endpoint.update(webhook_endpoint_params)
          render json: @webhook_endpoint
        else
          render json: { errors: @webhook_endpoint.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @webhook_endpoint.destroy
        head :no_content
      end

      private

      def set_webhook_endpoint
        @webhook_endpoint = @current_user.webhook_endpoints.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Webhook endpoint not found' }, status: :not_found
      end

      def ensure_pro_user
        unless @current_user.pro?
          render json: { error: 'Webhook management is a Pro only feature. Upgrade your plan to use it.' }, status: :forbidden
        end
      end

      def webhook_endpoint_params
        params.require(:webhook_endpoint).permit(:url, :active, events: [])
      end
    end
  end
end
