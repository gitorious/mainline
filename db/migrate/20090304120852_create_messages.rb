class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.integer :sender_id
      t.integer :recipient_id
      t.string :subject
      t.text :body
      t.string :notifiable_type
      t.integer :notifiable_id
      t.string :aasm_state
      t.integer :in_reply_to_id
      t.timestamps
    end
  end

  def self.down
    drop_table :messages
  end
end
