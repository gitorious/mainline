class RemoveMainlineFromRepositories < ActiveRecord::Migration
  def self.up
    remove_column :repositories, :mainline
  end

  def self.down
    add_column :repositories, :mainline, :boolean, :default => false
  end
end
