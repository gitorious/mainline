class RemovingTasks < ActiveRecord::Migration
  def self.up
    drop_table :tasks
  end

  def self.down
  end
end
