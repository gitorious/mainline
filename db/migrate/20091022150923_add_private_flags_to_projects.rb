class AddPrivateFlagsToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :private, :boolean, :default=>false
  end
  
  def self.down
    remove_column :projects, :private
  end
end
