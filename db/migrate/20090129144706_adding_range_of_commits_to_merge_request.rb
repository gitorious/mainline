class AddingRangeOfCommitsToMergeRequest < ActiveRecord::Migration
  def self.up
    add_column :merge_requests, :starting_commit, :string
    add_column :merge_requests, :ending_commit, :string
  end

  def self.down
    remove_column :merge_requests, :starting_commit
    remove_column :merge_requests, :ending_commit
  end
end
