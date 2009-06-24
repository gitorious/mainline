class RemoveVersionFromMergeRequests < ActiveRecord::Migration
  def self.up
    remove_column :merge_requests, :version
  end

  def self.down
    add_column :merge_requests, :version, :default => 0
  end
end
