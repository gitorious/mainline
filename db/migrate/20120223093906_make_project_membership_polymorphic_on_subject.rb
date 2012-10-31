class MakeProjectMembershipPolymorphicOnSubject < ActiveRecord::Migration
  def self.up
    add_column :project_memberships, :content_type, :string
    execute "update project_memberships set content_type='Project'"
    rename_table :project_memberships, :content_memberships
    rename_column :content_memberships, :project_id, :content_id
  end

  # Destructive - removes any non-project memberships
  def self.down
    rename_table :content_memberships, :project_memberships

    execute "delete from project_memberships where content_type='Project'"
    remove_column :project_memberships, :content_type
    rename_column :project_memberships, :content_id, :project_id
  end
end
