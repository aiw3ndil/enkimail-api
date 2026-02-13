module Api
  module V1
    class SubscriptionsController < ApplicationController
      skip_before_action :authenticate_request, only: [:webhook] if respond_to?(:authenticate_request)
      # If your ApplicationController uses a different authentication method, adjust accordingly.
      # Usually webhooks need to skip auth or use Stripe signature verification.

      def create
        # Create a Stripe Checkout Session
        session = Stripe::Checkout::Session.create({
          customer_email: current_user.email,
          payment_method_types: ['card'],
          line_items: [{
            price_data: {
              currency: 'usd',
              product_data: {
                name: 'EnkiMail Pro Plan',
                description: '10 domains, 15 senders, 1000 emails/day',
              },
              unit_amount: 299, # $2.99
              recurring: { interval: 'month' },
            },
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

        begin
          event = Stripe::Webhook.construct_event(
            payload, sig_header, ENV['STRIPE_WEBHOOK_SECRET']
          )
        rescue JSON::ParserError
          return head :bad_request
        rescue Stripe::SignatureVerificationError
          return head :bad_request
        end

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
        user_id = session.metadata.user_id
        user = User.find_by(id: user_id)
        return unless user

        user.update!(
          role: :pro,
          stripe_customer_id: session.customer,
          stripe_subscription_id: session.subscription
        )
      end

      def handle_subscription_deleted(subscription)
        user = User.find_by(stripe_subscription_id: subscription.id)
        return unless user

        user.update!(role: :standard, stripe_subscription_id: nil)
      end
    end
  end
end
