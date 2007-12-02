class AddSlugToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :slug, :string
    add_index  :projects, :slug, :unique => true
  end

  def self.down
    remove_column :projects, :slug
  end
end
