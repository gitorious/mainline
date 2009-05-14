class AddingUpdatedByToMergeRequests < ActiveRecord::Migration
  def self.up
    add_column :merge_requests, :updated_by_user_id, :integer
  end

  def self.down
    remove_column :merge_requests, :updated_by_user_id
  end
end
