class AddIndicesToEvents < ActiveRecord::Migration
  def self.up
    add_index :events, [:target_type, :target_id]
    add_index :events, :created_at
    add_index :events, :action
  end

  def self.down
    remove_index :events, [:target_type, :target_id]
    remove_index :events, :created_at
    remove_index :events, :action
  end
end
