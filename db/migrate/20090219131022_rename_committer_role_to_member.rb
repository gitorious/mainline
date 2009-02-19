class RenameCommitterRoleToMember < ActiveRecord::Migration
  def self.up
    Role.find_by_kind(1).update_attribute(:name, "Member")
  end

  def self.down
    Role.find_by_kind(1).update_attribute(:name, "Committer")
  end
end
