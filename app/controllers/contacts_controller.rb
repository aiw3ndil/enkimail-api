class ContactsController < ApplicationController
  before_action :set_contact, only: %i[ show update destroy ]

  # GET /contacts
  def index
    @contacts = Contact.all
    authorize Contact # authorize the collection
    render json: @contacts
  end

  # GET /contacts/1
  def show
    authorize @contact
    render json: @contact
  end

  # POST /contacts
  def create
    @contact = Contact.new(contact_params)
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_contact
      @contact = Contact.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "Contact not found" }, status: :not_found
    end

    # Only allow a list of trusted parameters through.
    def contact_params
      params.require(:contact).permit(:email, :first_name, :last_name, :status, custom_attributes: {})
    end
end
