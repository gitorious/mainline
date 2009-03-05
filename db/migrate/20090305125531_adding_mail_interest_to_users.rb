class AddingMailInterestToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :wants_email_notifications, :boolean, :default => false
  end

  def self.down
    remove_column :users, :wants_email_notifications
  end
end
