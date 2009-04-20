class AddWikiPermissionsToRepository < ActiveRecord::Migration
  def self.up
    add_column :repositories, :wiki_permissions, :integer, :default => 0
  end

  def self.down
    remove_column :repositories, :wiki_permissions
  end
end
