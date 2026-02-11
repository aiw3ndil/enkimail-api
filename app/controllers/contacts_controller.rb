class ContactsController < ApplicationController
  before_action :set_contact, only: %i[ show update destroy ]

  # GET /contacts
  def index
    @contacts = policy_scope(Contact)
    render json: @contacts
  end

  # GET /contacts/1
  def show
    authorize @contact
    render json: @contact
  end

  # POST /contacts
  def create
    @contact = Contact.new(contact_params.merge(user: current_user))
    authorize @contact

    if @contact.save
      render json: @contact, status: :created, location: @contact
    else
      render json: @contact.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /contacts/1
  def update
    authorize @contact
    if @contact.update(contact_params)
      render json: @contact
    else
      render json: @contact.errors, status: :unprocessable_entity
    end
  end

  # DELETE /contacts/1
  def destroy
    authorize @contact
    @contact.destroy
    head :no_content
  end

  # POST /contacts/import
  def import
    authorize Contact # authorize the action against the Contact class
    if params[:file].present? && params[:file].respond_to?(:read)
      ContactImportJob.perform_async(params[:file].read, current_user.id)
      render json: { message: 'Contact import has been queued.' }, status: :accepted
    else
      render json: { error: 'No CSV file provided.' }, status: :unprocessable_entity
    end
  end

  # GET /contacts/export
  def export
    authorize Contact # authorize the action against the Contact class
    ContactExportJob.perform_async(current_user.id)
    render json: { message: 'Contact export has been queued. You will receive an email with the download link shortly.' }, status: :accepted
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_contact
      @contact = Contact.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Contact not found" }, status: :not_found
    end

    # Only allow a list of trusted parameters through.
    def contact_params
      params.require(:contact).permit(:email, :first_name, :last_name, :status, :user_id, custom_attributes: {})
    end
end
