class AddReadyToSshKey < ActiveRecord::Migration
  def self.up
    add_column :ssh_keys, :ready, :boolean, :default => false
  end

  def self.down
    remove_column :ssh_keys, :ready
  end
end
