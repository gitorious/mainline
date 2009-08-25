class AddDefaultToMergeRequestStatuses < ActiveRecord::Migration
  def self.up
    add_column :merge_request_statuses, :default, :boolean, :default => false
  end

  def self.down
    remove_column :merge_request_statuses, :default
  end
end
