class CreateTasks < ActiveRecord::Migration
  def self.up
    create_table :tasks do |t|
      t.integer     :target_id
      t.string      :target_type
      t.string      :command
      t.boolean     :performed, :default => false
      t.datetime    :performed_at
      t.timestamps
    end
    add_index :tasks, :target_id
    add_index :tasks, :target_type
    add_index :tasks, :performed
  end

  def self.down
    drop_table :tasks
  end
end
