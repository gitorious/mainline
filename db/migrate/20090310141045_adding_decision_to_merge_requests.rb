class AddingDecisionToMergeRequests < ActiveRecord::Migration
  def self.up
    add_column :merge_requests, :reason, :text
  end

  def self.down
    remove_column :merge_requests, :reason
  end
end
