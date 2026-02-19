class AddUniqueIndexToContactListMemberships < ActiveRecord::Migration[7.1]
  def change
    # 1. Cleanup duplicates first
    # This keeps the record with the lowest ID and deletes the rest for each pair
    execute <<-SQL
      DELETE FROM contact_list_memberships a USING (
        SELECT MIN(id) as keep_id, contact_id, contact_list_id
        FROM contact_list_memberships
        GROUP BY contact_id, contact_list_id
        HAVING COUNT(*) > 1
      ) b
      WHERE a.contact_id = b.contact_id 
      AND a.contact_list_id = b.contact_list_id
      AND a.id <> b.keep_id
    SQL

    # 2. Remove existing non-unique indexes
    remove_index :contact_list_memberships, :contact_id if index_exists?(:contact_list_memberships, :contact_id)
    remove_index :contact_list_memberships, :contact_list_id if index_exists?(:contact_list_memberships, :contact_list_id)

    # 3. Add the unique combined index
    add_index :contact_list_memberships, [:contact_id, :contact_list_id], unique: true, name: 'index_memberships_on_contact_and_list'
    
    # 4. Add individual index for list_id back for performance (not unique)
    add_index :contact_list_memberships, :contact_list_id unless index_exists?(:contact_list_memberships, :contact_list_id)
  end
end
