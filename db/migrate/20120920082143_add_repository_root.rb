class AddRepositoryRoot < ActiveRecord::Migration
  def self.up
    create_table "repository_roots", :force => true do |t|
      t.string :path
      t.timestamps
    end
    add_column :projects, :repository_root_id, :integer, :default => nil
    add_column :projects, :offline_from, :timestamp, :default => nil
  end

  def self.down
    drop_table "repository_roots"
    remove_column :projects, :repository_root_id
    remove_column :projects, :offline_from
  end
end
