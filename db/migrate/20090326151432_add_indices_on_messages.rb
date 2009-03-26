class AddIndicesOnMessages < ActiveRecord::Migration
  def self.up
    add_index :messages, :sender_id
    add_index :messages, :recipient_id
    add_index :messages, [:notifiable_type, :notifiable_id]
    add_index :messages, :aasm_state
    add_index :messages, :in_reply_to_id
  end

  def self.down
    remove_index :messages, :sender_id
    remove_index :messages, :recipient_id
    remove_index :messages, [:notifiable_type, :notifiable_id]
    remove_index :messages, :aasm_state
    remove_index :messages, :in_reply_to_id
  end
end
