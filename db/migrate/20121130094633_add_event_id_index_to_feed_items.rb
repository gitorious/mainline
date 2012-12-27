class AddEventIdIndexToFeedItems < ActiveRecord::Migration
  def self.up
    add_index :feed_items, :event_id
  end

  def self.down
    remove_index :feed_items, :event_id
  end
end
