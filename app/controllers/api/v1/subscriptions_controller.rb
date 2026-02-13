module Api
  module V1
    class SubscriptionsController < ApplicationController
      skip_before_action :authenticate_request!, only: [:webhook] if respond_to?(:authenticate_request!)
      # If your ApplicationController uses a different authentication method, adjust accordingly.
      # Usually webhooks need to skip auth or use Stripe signature verification.

      def create
        # Create a Stripe Checkout Session
        puts "Debug: STRIPE_PRICE_ID is '#{ENV['STRIPE_PRICE_ID']}'"
        
        if ENV['STRIPE_PRICE_ID'].blank?
          return render json: { error: 'STRIPE_PRICE_ID is missing in server environment' }, status: :internal_server_error
        end

        session = Stripe::Checkout::Session.create({
          customer_email: current_user.email,
          payment_method_types: ['card'],
          line_items: [{
            price: ENV['STRIPE_PRICE_ID'],
            quantity: 1,
          }],
          mode: 'subscription',
          success_url: "#{params[:success_url]}?session_id={CHECKOUT_SESSION_ID}",
          cancel_url: params[:cancel_url],
          metadata: {
            user_id: current_user.id
          }
        })

        render json: { checkout_url: session.url }, status: :ok
      rescue Stripe::StripeError => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def webhook
        payload = request.body.read
        sig_header = request.env['HTTP_STRIPE_SIGNATURE']
        event = nil

        Rails.logger.info "Stripe Webhook received: sig_header present? #{sig_header.present?}"

        begin
          event = Stripe::Webhook.construct_event(
            payload, sig_header, ENV['STRIPE_WEBHOOK_SECRET']
          )
        rescue JSON::ParserError => e
          Rails.logger.error "Webhook JSON Parser Error: #{e.message}"
          return head :bad_request
        rescue Stripe::SignatureVerificationError => e
          Rails.logger.error "Webhook Signature verify Error: #{e.message}. Secret present? #{ENV['STRIPE_WEBHOOK_SECRET'].present?}"
          return head :bad_request
        end

        Rails.logger.info "Stripe Event Processed: #{event.type}"

        # Handle the event
        case event.type
        when 'checkout.session.completed'
          session = event.data.object
          handle_checkout_session(session)
        when 'customer.subscription.deleted'
          subscription = event.data.object
          handle_subscription_deleted(subscription)
        end

        head :ok
      end

      private

      def handle_checkout_session(session)
        user_id = session.metadata&.user_id
        Rails.logger.info "Handling checkout session for user_id: #{user_id}"
        
        user = User.find_by(id: user_id)
        if user
          user.update!(
            role: :pro,
            stripe_customer_id: session.customer,
            stripe_subscription_id: session.subscription
          )
          Rails.logger.info "User #{user.email} upgraded to PRO via webhook"
        else
          Rails.logger.error "User not found for user_id: #{user_id} in metadata"
        end
      end

      def handle_subscription_deleted(subscription)
        user = User.find_by(stripe_subscription_id: subscription.id)
        return unless user

        user.update!(role: :standard, stripe_subscription_id: nil)
      end
    end
  end
end
