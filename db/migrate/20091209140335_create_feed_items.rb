class CreateFeedItems < ActiveRecord::Migration
  def self.up
    create_table :feed_items do |t|
      t.integer :event_id
      t.integer :watcher_id
      t.timestamps
    end
    add_index :feed_items, [:watcher_id, :created_at]
  end

  def self.down
    drop_table :feed_items
  end
end
