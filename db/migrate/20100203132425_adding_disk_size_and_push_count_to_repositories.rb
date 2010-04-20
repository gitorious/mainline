class AddingDiskSizeAndPushCountToRepositories < ActiveRecord::Migration
  def self.up
    add_column :repositories, :disk_usage, :integer
    add_column :repositories, :push_count_since_gc, :integer
  end

  def self.down
    remove_column :repositories, :disk_usage
    remove_column :repositories, :push_count_since_gc
  end
end
