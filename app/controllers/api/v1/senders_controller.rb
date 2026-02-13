module Api
  module V1
    class SendersController < ApplicationController
      before_action :set_sender, only: [:show, :destroy]

      # GET /senders
      def index
        @senders = current_user.senders
        render json: @senders
      end

      # GET /senders/:id
      def show
        render json: @sender
      end

      # POST /senders
      def create
        @sender = current_user.senders.new(sender_params)

        # Attempt to link to a verified domain if email matches
        domain_name = @sender.email.split('@').last
        domain = current_user.domains.find_by(name: domain_name)
        
        if domain
          @sender.domain = domain
        else
          return render json: { error: "No verified domain found for #{domain_name}. Please add and verify the domain first." }, status: :unprocessable_entity
        end

        if @sender.save
          render json: @sender, status: :created
        else
          render json: @sender.errors, status: :unprocessable_entity
        end
      end

      # DELETE /senders/:id
      def destroy
        @sender.destroy
        head :no_content
      end

      private

      def set_sender
        @sender = current_user.senders.find(params[:id])
      end

      def sender_params
        params.require(:sender).permit(:email, :name)
      end
    end
  end
end
