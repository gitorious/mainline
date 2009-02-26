class AddEmailToggleToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :public_email, :boolean, :default => true
  end

  def self.down
    remove_column :users, :public_email
  end
end
