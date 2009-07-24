class AddNotifyCommittersOnNewMergeRequestToRepositories < ActiveRecord::Migration
  def self.up
    add_column :repositories, :notify_committers_on_new_merge_request, :boolean, :default => true
  end

  def self.down
    remove_column :repositories, :notify_committers_on_new_merge_request
  end
end
