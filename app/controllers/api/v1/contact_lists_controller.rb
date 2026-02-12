class Api::V1::ContactListsController < ApplicationController
  before_action :set_contact_list, only: %i[ show update destroy add_contact remove_contact ]

  # GET /contact_lists
  def index
    @contact_lists = policy_scope(ContactList)
    render json: @contact_lists
  end

  # GET /contact_lists/1
  def show
    authorize @contact_list
    render json: @contact_list.to_json(include: :contacts) # Include contacts in the show action
  end

  # POST /contact_lists
  def create
    @contact_list = ContactList.new(contact_list_params.merge(user: current_user))
    authorize @contact_list

    if @contact_list.save
      render json: @contact_list, status: :created, location: @contact_list
    else
      render json: @contact_list.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /contact_lists/1
  def update
    authorize @contact_list
    if @contact_list.update(contact_list_params)
      render json: @contact_list
    else
      render json: @contact_list.errors, status: :unprocessable_entity
    end
  end

  # DELETE /contact_lists/1
  def destroy
    authorize @contact_list
    @contact_list.destroy
    head :no_content
  end

  # POST /contact_lists/:id/add_contact
  def add_contact
    authorize @contact_list
    contact = Contact.find(params[:contact_id])
    if @contact_list.contacts << contact
      render json: @contact_list.contacts, status: :ok
    else
      render json: { error: "Contact already in this list or other error" }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Contact not found" }, status: :not_found
  end

  # DELETE /contact_lists/:id/remove_contact
  def remove_contact
    authorize @contact_list
    contact = Contact.find(params[:contact_id])
    if @contact_list.contacts.delete(contact)
      render json: @contact_list.contacts, status: :ok
    else
      render json: { error: "Contact not in this list" }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Contact not found" }, status: :not_found
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_contact_list
      @contact_list = ContactList.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { error: "ContactList not found" }, status: :not_found
    end

    # Only allow a list of trusted parameters through.
    def contact_list_params
      params.require(:contact_list).permit(:name, :description, :user_id)
    end
end
