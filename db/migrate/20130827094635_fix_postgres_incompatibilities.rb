class FixPostgresIncompatibilities < ActiveRecord::Migration
  def up
    rename_index "content_memberships", "project_memberships_index", "content_memberships_index"
  end

  def down
    rename_index "content_memberships", "content_memberships_index", "project_memberships_index"
  end
end
