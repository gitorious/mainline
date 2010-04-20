class CreateHooks < ActiveRecord::Migration
  def self.up
    create_table :hooks do |t|
      t.integer :user_id
      t.integer :repository_id
      t.string :url
      t.string :last_response
      t.timestamps
    end
    add_index :hooks, :repository_id
  end

  def self.down
    drop_table :hooks
  end
end
