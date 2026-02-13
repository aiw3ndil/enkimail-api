module Api
  module V1
    class DomainsController < ApplicationController
      before_action :set_domain, only: [:show, :destroy, :verify]

      # GET /domains
      def index
        @domains = current_user.domains
        render json: @domains
      end

      # GET /domains/:id
      def show
        render json: @domain
      end

      # POST /domains
      def create
        @domain = current_user.domains.new(domain_params)

        if @domain.save
          render json: @domain, status: :created
        else
          render json: @domain.errors, status: :unprocessable_entity
        end
      end

      # DELETE /domains/:id
      def destroy
        @domain.destroy
        head :no_content
      end

      # POST /domains/:id/verify
      def verify
        # Placeholder for DNS verification logic
        # In a real implementation, we would use Resolv::DNS to check TXT records
        
        # Simulating verification for now or implementing basic check if possible
        # We'll implement actual check in next step
        
        if @domain.verified? # Just returning current status for now until logic is added
             render json: { message: 'Domain is already verified', domain: @domain }
        else
             # Trigger verification job or service
             VerifyDomainJob.perform_later(@domain.id)
             render json: { message: 'Verification queued', domain: @domain }
        end
      end

      private

      def set_domain
        @domain = current_user.domains.find(params[:id])
      end

      def domain_params
        params.require(:domain).permit(:name)
      end
    end
  end
end
