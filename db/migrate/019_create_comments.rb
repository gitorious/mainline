class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.integer :user_id, :null => false
      t.integer :repository_id, :null => false
      t.string  :sha1, :null => true
      t.text    :body
      t.timestamps
    end
    add_index :comments, :user_id
    add_index :comments, :repository_id
    add_index :comments, :sha1
  end

  def self.down
    drop_table :comments
  end
end
