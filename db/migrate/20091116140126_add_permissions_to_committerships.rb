class AddPermissionsToCommitterships < ActiveRecord::Migration
  def self.up
    transaction do
      add_column :committerships, :permissions, :integer
      ActiveRecord::Base.reset_column_information
      base_perms = Committership::CAN_REVIEW | Committership::CAN_COMMIT
      Committership.update_all("permissions = #{base_perms}")
    end
  end

  def self.down
    remove_column :committerships, :permissions
  end
end
