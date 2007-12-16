class CreateTasks < ActiveRecord::Migration
  def self.up
    create_table :tasks do |t|
      t.string      :target_class
      t.string      :command
      t.text      :arguments
      t.boolean     :performed, :default => false
      t.datetime    :performed_at
      t.timestamps
    end
    add_index :tasks, :performed
  end

  def self.down
    drop_table :tasks
  end
end
