class AddSummaryToMergeRequests < ActiveRecord::Migration
  def self.up
    add_column :merge_requests, :summary, :string, :null => false
  end

  def self.down
    remove_column :merge_requests, :summary
  end
end
