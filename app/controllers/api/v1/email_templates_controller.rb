class Api::V1::EmailTemplatesController < ApplicationController
  before_action :set_email_template, only: %i[ show update destroy ]

  # GET /email_templates
  def index
    @email_templates = Api::V1::EmailTemplatePolicy::Scope.new(current_user, EmailTemplate).resolve
    render json: @email_templates
  end

  # GET /email_templates/1
  def show
    authorize @email_template, policy_class: Api::V1::EmailTemplatePolicy
    render json: @email_template
  end

  # POST /email_templates
  def create
    @email_template = EmailTemplate.new(email_template_params.merge(user: current_user))
    authorize @email_template, policy_class: Api::V1::EmailTemplatePolicy

    if @email_template.save
      render json: @email_template, status: :created, location: api_v1_email_template_url(@email_template)
    else
      render json: @email_template.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /email_templates/1
  def update
    authorize @email_template, policy_class: Api::V1::EmailTemplatePolicy
    if @email_template.update(email_template_params)
      render json: @email_template
    else
      render json: @email_template.errors, status: :unprocessable_entity
    end
  end

  # DELETE /email_templates/1
  def destroy
    authorize @email_template, policy_class: Api::V1::EmailTemplatePolicy
    @email_template.destroy
    head :no_content
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_email_template
      @email_template = EmailTemplate.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "EmailTemplate not found" }, status: :not_found
    end

    # Only allow a list of trusted parameters through.
    def email_template_params
      params.require(:email_template).permit(:name, :subject, :body, :plain_text_body, :user_id)
    end
end
