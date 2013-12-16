class AddIndexesToMessagesUsers < ActiveRecord::Migration
  def change
    add_index :messages_users, :recipient_id
    add_index :messages_users, :message_id
  end
end
