class CreateSshKeys < ActiveRecord::Migration
  def self.up
    create_table :ssh_keys do |t|
      t.integer :user_id
      t.text  :key
      t.timestamps
    end
    remove_column :users, :ssh_key
    add_column :users, :ssh_key_id, :integer
    add_index :ssh_keys, :user_id
    add_index :users, :ssh_key_id
  end

  def self.down
    drop_table :ssh_keys
    add_column :users, :ssh_key, :text
    remove_column :users, :ssh_key_id
  end
end
