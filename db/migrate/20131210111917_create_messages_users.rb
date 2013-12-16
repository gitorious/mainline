class CreateMessagesUsers < ActiveRecord::Migration
  def up
    create_table :messages_users do |t|
      t.belongs_to :message, null: false
      t.belongs_to :recipient, null: false
    end

    execute <<-SQL
    INSERT INTO messages_users (message_id, recipient_id)
      SELECT messages.id, messages.recipient_id FROM messages;
    SQL

    remove_column :messages, :recipient_id
  end

  def down
    add_column :messages, :recipient_id, :integer, null: false

    execute <<-SQL
    UPDATE messages AS m
      LEFT JOIN messages_users AS mu
        ON m.id = mu.message_id
      SET m.recipient_id = mu.recipient_id;
    SQL

    drop_table :messages_users
  end
end
