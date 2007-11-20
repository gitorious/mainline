class AddMoreInfoToProjects < ActiveRecord::Migration
  def self.up
    add_column :projects, :license, :string
    add_column :projects, :home_url, :string
    add_column :projects, :mailinglist_url, :string
    add_column :projects, :bugtracker_url, :string
  end

  def self.down
    remove_column :projects, :license
    remove_column :projects, :home_url
    add_column :projects, :mailinglist_url
    add_column :projects, :bugtracker_url
  end
end
