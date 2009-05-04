class RemoveTosAttributeFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :terms_of_use
  end

  def self.down
    add_column :users, :terms_of_use, :boolean, :default => false
  end
end
