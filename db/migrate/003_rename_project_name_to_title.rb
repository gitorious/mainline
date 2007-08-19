class RenameProjectNameToTitle < ActiveRecord::Migration
  def self.up
    rename_column :projects, :name, :title
  end

  def self.down
    rename_column :projects, :title, :name
  end
end
