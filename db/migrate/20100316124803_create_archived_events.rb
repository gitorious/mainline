class CreateArchivedEvents < ActiveRecord::Migration
  def self.up
    create_table :archived_events do |t|
      t.integer :user_id
      t.integer :project_id
      t.integer :action
      t.string :data
      t.text :body
      t.integer :target_id
      t.string :target_type
      t.string :user_email
      t.timestamps
    end
  end

  def self.down
    drop_table :archived_events
  end
end
