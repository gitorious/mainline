class AddSshKeyToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :ssh_key, :text
  end

  def self.down
    remove_column :users, :ssh_key
  end
end
