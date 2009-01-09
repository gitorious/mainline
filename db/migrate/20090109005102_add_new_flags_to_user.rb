class AddNewFlagsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :is_admin, :boolean, :default => false
    add_column :users, :suspended_at, :datetime
  end

  def self.down
    remove_column :users, :is_admin
    remove_column :users, :suspended_at
  end
end
