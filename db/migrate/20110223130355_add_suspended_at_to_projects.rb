class AddSuspendedAtToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :suspended_at, :datetime, :default => nil
  end

  def self.down
    remove_column :projects, :suspended_at
  end
end
