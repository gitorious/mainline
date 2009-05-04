class RemovingStartingCommitFromMergeRequests < ActiveRecord::Migration
  def self.up
    remove_column :merge_requests, :starting_commit
  end

  def self.down
    add_column :merge_requests, :starting_commit, :string    
  end
end
