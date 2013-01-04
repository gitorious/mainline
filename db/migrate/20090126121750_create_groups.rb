class CreateGroups < ActiveRecord::Migration
  def self.up
    transaction do
      create_table :groups do |t|
        t.string    :name
        t.boolean   :public, :default => true
        t.integer   :user_id
        t.integer   :project_id
        t.timestamps
      end
      add_index :groups, [:name, :public]
      add_index :groups, :user_id
      add_index :groups, [:project_id, :public]

      create_table :roles do |t|
        t.string      :name
        t.integer     :kind
        t.timestamps
      end

      Role.reset_column_information
      Role.create!(:name => "Administrator", :kind => Role::KIND_ADMIN)
      Role.create!(:name => "Committer", :kind => Role::KIND_MEMBER)

      create_table :memberships do |t|
        t.integer     :group_id
        t.integer     :user_id
        t.integer     :role_id
        t.timestamps
      end
      add_index :memberships, [:group_id, :user_id]
    end
  end

  def self.down
    transaction do
      drop_table :groups
      drop_table :memberships
    end
  end
end
