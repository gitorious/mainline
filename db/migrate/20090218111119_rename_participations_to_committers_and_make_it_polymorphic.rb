class RenameParticipationsToCommittersAndMakeItPolymorphic < ActiveRecord::Migration
  def self.up
    rename_table :participations, :committerships
    rename_column :committerships, :group_id, :committer_id
    add_column :committerships, :committer_type, :string
    add_index :committerships, [:committer_id, :committer_type]

    ActiveRecord::Base.reset_column_information
    Committership.update_all("committer_type = 'Group'")
  end

  def self.down
    rename_table :committerships, :participations
    rename_column :committerships, :committer_id, :group_id
    remove_column :committerships, :committer_type
  end
end
