class MakeUsersWantEmailByDefault < ActiveRecord::Migration
  def self.up
    change_column :users, :wants_email_notifications, :boolean, :default => true
  end

  def self.down
    change_column :users, :wants_email_notifications, :boolean
  end
end
