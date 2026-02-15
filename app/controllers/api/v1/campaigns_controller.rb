class Api::V1::CampaignsController < Api::V1::ApplicationController
  before_action :set_campaign, only: %i[ show update destroy send_campaign ]

  # GET /campaigns
  def index
    @campaigns = policy_scope(Campaign)
    render json: @campaigns.to_json(include: [:email_template, :contact_list])
  end

  # GET /campaigns/1
  def show
    authorize @campaign
    render json: @campaign.to_json(include: [:email_template, :contact_list])
  end

  # POST /campaigns
  def create
    @campaign = Campaign.new(campaign_params.merge(user: current_user))
    authorize @campaign

    if @campaign.save
      render json: @campaign.to_json(include: [:email_template, :contact_list]), status: :created
    else
      render json: @campaign.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /campaigns/1
  def update
    authorize @campaign
    if @campaign.update(campaign_params)
      render json: @campaign.to_json(include: [:email_template, :contact_list])
    else
      render json: @campaign.errors, status: :unprocessable_entity
    end
  end

  # DELETE /campaigns/1
  def destroy
    authorize @campaign
    @campaign.destroy
    head :no_content
  end

  # POST /campaigns/:id/send
  def send_campaign
    Rails.logger.info "--- Entering send_campaign action ---"
    authorize @campaign, :send? # Authorize with a specific Pundit action

    Rails.logger.debug "DEBUG: campaign_params[:scheduled_at] = #{campaign_params[:scheduled_at].inspect}"
    if campaign_params[:scheduled_at].present?
      parsed_time = Time.parse(campaign_params[:scheduled_at])
      Rails.logger.debug "DEBUG: parsed_time = #{parsed_time.inspect}"
      Rails.logger.debug "DEBUG: Time.current = #{Time.current.inspect}"
      Rails.logger.debug "DEBUG: parsed_time > Time.current = #{parsed_time > Time.current}"
    end

    if @campaign.draft?
      if campaign_params[:scheduled_at].present? && Time.parse(campaign_params[:scheduled_at]) > Time.current
        @campaign.update(status: :scheduled, scheduled_at: campaign_params[:scheduled_at])
        CampaignSenderJob.set(wait_until: @campaign.scheduled_at).perform_later(@campaign.id)
        render json: { status: 'success', message: 'Campaign scheduled for delivery', campaign: @campaign.to_json(include: [:email_template, :contact_list]) }, status: :accepted
      else
        @campaign.update(status: :sending) # A new temporary status for immediately sending
        CampaignSenderJob.perform_later(@campaign.id)
        render json: { status: 'success', message: 'Campaign queued for immediate sending', campaign: @campaign.to_json(include: [:email_template, :contact_list]) }, status: :accepted
      end
    else
      render json: { status: 'error', message: 'Campaign must be in draft status to be sent or scheduled' }, status: :unprocessable_entity
    end
  rescue Pundit::NotAuthorizedError
    render json: { error: "You are not authorized to send this campaign." }, status: :forbidden
  rescue => e
    render json: { status: 'error', message: e.message }, status: :internal_server_error
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_campaign
      @campaign = Campaign.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Campaign not found" }, status: :not_found
    end

    # Only allow a list of trusted parameters through.
    def campaign_params
      params.require(:campaign).permit(:name, :subject, :status, :email_template_id, :contact_list_id, :user_id, :scheduled_at)
    end

end
