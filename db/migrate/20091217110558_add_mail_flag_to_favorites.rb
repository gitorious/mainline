class AddMailFlagToFavorites < ActiveRecord::Migration
  def self.up
    add_column :favorites, :notify_by_email, :boolean, :default => false
  end

  def self.down
    remove_column :favorites, :notify_by_email
  end
end
