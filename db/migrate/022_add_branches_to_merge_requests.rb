class AddBranchesToMergeRequests < ActiveRecord::Migration
  def self.up
    add_column :merge_requests, :source_branch, :string
    add_column :merge_requests, :target_branch, :string
  end

  def self.down
    remove_column :merge_requests, :source_branch
    remove_column :merge_requests, :target_branch
  end
end
