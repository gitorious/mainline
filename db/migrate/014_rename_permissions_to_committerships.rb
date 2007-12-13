class RenamePermissionsToCommitterships < ActiveRecord::Migration
  def self.up
    rename_table :permissions, :committerships
  end

  def self.down
    rename_table :committerships, :permissions
  end
end
