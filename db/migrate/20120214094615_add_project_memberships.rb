class AddProjectMemberships < ActiveRecord::Migration
  def self.up
    create_table :project_memberships do |t|
      t.integer :project_id
      t.string :member_type
      t.integer :member_id
      t.timestamps
    end
    add_index :project_memberships, [:project_id, :member_id, :member_type], :name => "project_memberships_index"
  end

  def self.down
    drop_table :project_memberships
  end
end
