class AddTargetIdToTasks < ActiveRecord::Migration
  def self.up
    add_column :tasks, :target_id, :integer
  end

  def self.down
    remove_column :tasks, :target_id
  end
end
