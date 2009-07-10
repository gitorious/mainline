class AddDenyforcePushingToRepositories < ActiveRecord::Migration
  def self.up
    add_column :repositories, :deny_force_pushing, :boolean, :default => false
  end

  def self.down
    remove_column :repositories, :deny_force_pushing
  end
end
