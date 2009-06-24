class AddProjectsCreatedAtIndexOnEvents < ActiveRecord::Migration
  def self.up
    add_index :events, [:created_at, :project_id]
  end

  def self.down
    remove_index :events, [:created_at, :project_id]
  end
end
