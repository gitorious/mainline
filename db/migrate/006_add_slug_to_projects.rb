class AddSlugToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :slug, :string
    add_index  :projects, :slug
  end

  def self.down
    remove_column :projects, :slug
  end
end
