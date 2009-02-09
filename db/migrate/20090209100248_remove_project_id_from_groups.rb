class RemoveProjectIdFromGroups < ActiveRecord::Migration
  def self.up
    remove_column :groups, :project_id
  end

  def self.down
    add_column :groups, :project_id, :integer
  end
end
