class AddingMergeRequestsNeedSignoffToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :merge_requests_need_signoff, :boolean, :default => false
  end

  def self.down
    remove_column :projects, :merge_requests_need_signoff
  end
end
