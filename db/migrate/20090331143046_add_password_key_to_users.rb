class AddPasswordKeyToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :password_key, :string
    add_index :users, :password_key
  end

  def self.down
    remove_column :users, :password_key
  end
end
