class ProjectMembership < ActiveRecord::Base
  belongs_to :project
  belongs_to :member, :polymorphic => true
end

class MakeProjectMembershipPolymorphicOnSubject < ActiveRecord::Migration
  def self.up
    add_column :project_memberships, :content_type, :string
    ProjectMembership.all.each do |pm|
      pm.content_type = "Project"
      pm.save!
    end
    rename_table :project_memberships, :content_memberships
    rename_column :content_memberships, :project_id, :content_id
  end

  # Destructive - removes any non-project memberships
  def self.down
    rename_table :content_memberships, :project_memberships

    ProjectMembership.all.each do |pm|
      pm.delete if pm.content_type != "Project"
    end

    remove_column :project_memberships, :content_type
    rename_column :project_memberships, :content_id, :project_id
  end
end
