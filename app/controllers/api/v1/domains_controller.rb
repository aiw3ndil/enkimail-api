module Api
  module V1
    class DomainsController < ApplicationController
      before_action :set_domain, only: [:show, :destroy, :verify]

      # GET /domains
      def index
        @domains = current_user.domains
        render json: @domains.map { |domain| domain_with_records(domain) }
      end

      # GET /domains/:id
      def show
        render json: domain_with_records(@domain)
      end

      # POST /domains
      def create
        @domain = current_user.domains.new(domain_params)

        if @domain.save
          render json: domain_with_records(@domain), status: :created
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
        if @domain.verified?
          render json: { message: 'Domain is already verified', domain: domain_with_records(@domain) }
        else
          @domain.update(verification_attempts: @domain.verification_attempts + 1, verification_sent_at: Time.current)
          VerifyDomainJob.perform_later(@domain.id)
          render json: { message: 'Verification queued', domain: domain_with_records(@domain) }
        end
      end

      private

      def set_domain
        @domain = current_user.domains.find(params[:id])
      end

      def domain_params
        params.require(:domain).permit(:name)
      end
      
      def domain_with_records(domain)
        domain.as_json.merge(
          dns_instructions: domain.dns_instructions
        )
      end
    end
  end
end
