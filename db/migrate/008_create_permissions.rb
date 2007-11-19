class CreatePermissions < ActiveRecord::Migration
  def self.up
    create_table :permissions do |t|
      t.integer :user_id
      t.integer :repository_id
      t.integer :kind, :default => 2

      t.timestamps
    end
    add_index :permissions, :user_id
    add_index :permissions, :repository_id
  end

  def self.down
    drop_table :permissions
  end
end
