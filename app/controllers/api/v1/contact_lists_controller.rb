class Api::V1::ContactListsController < Api::V1::ApplicationController
  before_action :set_contact_list, only: %i[ show update destroy add_contact add_contacts remove_contact ]

  # GET /contact_lists
  def index
    @contact_lists = policy_scope(ContactList)
    render json: @contact_lists.as_json(methods: :contacts_count)
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
      render json: @contact_list, status: :created
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

  # POST /contact_lists/:id/add_contacts
  def add_contacts
    authorize @contact_list
    contact_ids = params[:contact_ids]

    if contact_ids.blank? || !contact_ids.is_a?(Array)
      return render json: { error: "No contact_ids provided or format is not an array." }, status: :unprocessable_entity
    end

    # Security: Ensure we only add contacts that belong to the current user
    valid_contact_ids = current_user.contacts.where(id: contact_ids).pluck(:id)
    
    if valid_contact_ids.empty?
      return render json: { message: "No valid contacts found to add." }, status: :ok
    end

    # Build memberships to insert
    now = Time.current
    memberships = valid_contact_ids.map do |contact_id|
      { 
        contact_id: contact_id, 
        contact_list_id: @contact_list.id,
        created_at: now,
        updated_at: now
      }
    end

    # Use insert_all to skip validations and handle duplicates automatically.
    # We use a rescue block in case the unique index hasn't been migrated yet.
    begin
      ContactListMembership.insert_all(memberships, unique_by: [:contact_id, :contact_list_id])
    rescue ArgumentError => e
      if e.message.include?("No unique index found")
        # Fallback for when the migration hasn't been run
        # Still relatively efficient: find existing IDs and insert only new ones
        existing_ids = @contact_list.contact_list_memberships.where(contact_id: contact_ids).pluck(:contact_id)
        new_ids = contact_ids.map(&:to_i) - existing_ids
        
        new_memberships = new_ids.map do |contact_id|
          { 
            contact_id: contact_id, 
            contact_list_id: @contact_list.id,
            created_at: now,
            updated_at: now
          }
        end
        ContactListMembership.insert_all(new_memberships) if new_memberships.any?
      else
        raise e
      end
    end
    
    render json: { message: "Successfully added #{contact_ids.size} contacts to the list.", count: @contact_list.contacts.count }, status: :ok
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
