module Gitorious
  class Project < ActiveRecord::Base
    default_scope :conditions => [""]
  end
end

class AddOwnerToProjects < ActiveRecord::Migration
  def self.up
    transaction do
      add_column :projects, :owner_id, :integer
      add_column :projects, :owner_type, :string
      add_index :projects, [:owner_type, :owner_id]

      Gitorious::Project.reset_column_information

      Gitorious::Project.all.each do |project|
        project.update_attribute(:owner_id, project.user_id)
        project.update_attribute(:owner_type, "User")
      end
    end
  end

  def self.down
    remove_column :projects, :owner_id
    remove_column :projects, :owner_type
  end
end
