class AddingMergeRequestStatusToProject < ActiveRecord::Migration
  def self.up
    add_column :projects, :merge_request_custom_states, :text
  end

  def self.down
    remove_column :projects, :merge_request_custom_states
  end
end
