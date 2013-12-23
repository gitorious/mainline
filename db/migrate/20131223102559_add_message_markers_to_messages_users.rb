class AddMessageMarkersToMessagesUsers < ActiveRecord::Migration
  def up
    add_column :messages_users, :read, :boolean, :null => false, :default => false

    execute <<-SQL
    UPDATE messages_users AS mu LEFT JOIN messages AS m ON m.id = mu.message_id
      SET mu.read = 1
      WHERE m.aasm_state = 'read'
    SQL

    remove_column :messages, :aasm_state
  end

  def down
    add_column :messages, :aasm_state, :string

    execute <<-SQL
    UPDATE messages AS m LEFT JOIN messages_users AS mu ON m.id = mu.message_id
      SET m.aasm_state = 'read'
      WHERE mu.read = 1
    SQL

    remove_column :messages_users, :read
  end
end
