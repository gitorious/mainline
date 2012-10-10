class ContentMembership < ActiveRecord::Base
  belongs_to :project
  belongs_to :member, :polymorphic => true
end

class MakeProjectMembershipPolymorphicOnSubject < ActiveRecord::Migration
  def self.up
    rename_table :project_memberships, :content_memberships
    rename_column :content_memberships, :project_id, :content_id
    add_column :content_memberships, :content_type, :string
    ContentMembership.all.each do |cm|
      cm.content_type = "Project"
      cm.save!
    end
  end

  # Destructive - removes any non-project memberships
  def self.down
    ContentMembership.all.each do |cm|
      cm.delete if cm.content_type != "Project"
    end

    remove_column :content_memberships, :content_type
    rename_column :content_memberships, :content_id, :project_id

    rename_table :content_memberships, :project_memberships
  end
end
