class RejiggingMergeRequests < ActiveRecord::Migration
  def self.up
    add_column :merge_requests, :version, :integer, :default => 0
  end

  def self.down
    remove_column :merge_requests, :version
  end
end
