class AddingStatusTagToMergeRequests < ActiveRecord::Migration
  def self.up
    add_column :merge_requests, :status_tag, :string
  end

  def self.down
    remove_column :merge_requests, :status_tag
  end
end
