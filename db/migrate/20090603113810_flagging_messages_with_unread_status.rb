class FlaggingMessagesWithUnreadStatus < ActiveRecord::Migration
  def self.up
    add_column :messages, :root_message_id, :integer
    add_column :messages, :has_unread_replies, :boolean, :default => false
  end

  def self.down
    remove_column :messages, :root_message_id
    remove_column :messages, :has_unread_replies
  end
end
