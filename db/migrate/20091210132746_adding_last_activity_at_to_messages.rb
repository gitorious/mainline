class AddingLastActivityAtToMessages < ActiveRecord::Migration
  def self.up
    add_column :messages, :last_activity_at, :datetime
    execute("UPDATE messages SET last_activity_at=updated_at")
  end

  def self.down
    remove_column :messages, :last_activity_at
  end
end
