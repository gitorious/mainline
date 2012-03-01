class CreateGitoriousServers < ActiveRecord::Migration
  def self.up
    create_table :gitorious_servers do |t|
      t.string :hostname
      t.timestamps
    end
    add_column :projects, :gitorious_server_id, :integer, :default => nil
  end

  def self.down
    drop_table :gitorious_servers
    remove_column :projects, :gitorious_server_id
  end
end
