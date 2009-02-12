class AddWikiEnabledToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :wiki_enabled, :boolean, :default => true
  end

  def self.down
    remove_column :projects, :wiki_enabled
  end
end
