class AddingDefaultFavoriteNotificationToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :default_favorite_notifications, :boolean, :default => false
  end

  def self.down
    remove_column :users, :default_favorite_notifications
  end
end
