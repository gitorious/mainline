class AddingMergeRequestOptionToMergeRequests < ActiveRecord::Migration
  def self.up
    add_column :repositories, :merge_requests_enabled, :boolean, :default => true
  end

  def self.down
    remove_column :repositories, :merge_requests_enabled
  end
end
