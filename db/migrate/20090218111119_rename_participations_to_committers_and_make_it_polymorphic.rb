class RenameParticipationsToCommittersAndMakeItPolymorphic < ActiveRecord::Migration
  def self.up
    rename_column :committerships, :user_id, :committer_id
    change_column :committerships, :committer_id, :integer, :null => true
    add_column :committerships, :committer_type, :string, :null => false
    add_column :committerships, :creator_id, :integer

    add_index :committerships, [:committer_id, :committer_type]
    add_index :committerships, :repository_id

    Committership.reset_column_information
    Committership.update_all("committer_type = 'User'")
  end

  def self.down
    rename_column :committerships, :committer_id, :user_id
    remove_column :committerships, :committer_type
    remove_column :committerships, :creator_id
  end
end
