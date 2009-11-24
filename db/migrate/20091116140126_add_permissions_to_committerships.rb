class AddPermissionsToCommitterships < ActiveRecord::Migration
  def self.up
    transaction do
      add_column :committerships, :permissions, :integer
      ActiveRecord::Base.reset_column_information
      base_perms = Committership::CAN_REVIEW | Committership::CAN_COMMIT
      say_with_time("Updating existing permissions") do
        Committership.find(:all, :include => {:repository => [:user]}).each do |c|
          if c.repository &&
              (c.committer == c.repository.owner || c.committer == c.repository.user)
            c.permissions = base_perms | Committership::CAN_ADMIN
          else
            c.permissions = base_perms
          end
          c.save!
        end
      end
    end
  end

  def self.down
    remove_column :committerships, :permissions
  end
end
