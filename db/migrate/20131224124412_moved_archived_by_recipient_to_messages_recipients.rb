class MovedArchivedByRecipientToMessagesRecipients < ActiveRecord::Migration
  def up
    add_column :messages_users, :archived, :boolean, :null => false, :default => false

    execute <<-SQL
    UPDATE messages_users AS mu LEFT JOIN messages AS m ON m.id = mu.message_id
      SET mu.archived = 1
      WHERE m.archived_by_recipient = 1
    SQL

    remove_column :messages, :archived_by_recipient
  end

  def down
    add_column :messages, :archived_by_recipient, :boolean, :default => false

    execute <<-SQL
    UPDATE messages AS m LEFT JOIN messages_users AS mu ON m.id = mu.message_id
      SET m.archived_by_recipient = 1
      WHERE mu.archived = 1
    SQL

    remove_column :messages_users, :archived
  end
end
