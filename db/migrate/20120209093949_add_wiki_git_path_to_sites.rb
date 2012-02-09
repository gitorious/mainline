class AddWikiGitPathToSites < ActiveRecord::Migration
   def self.up
    add_column :sites, :wiki_git_path, :text
  end

  def self.down
    remove_column :sites, :wiki_git_path
  end
end
