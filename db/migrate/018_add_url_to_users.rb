class AddUrlToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :url, :text
  end

  def self.down
    remove_column :users, :url
  end
end
