class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.integer           :user_id, :null => false
      t.integer           :project_id, :null => false
      t.integer           :action, :null => false
      t.string            :data # Additional data
      t.text              :body
      
      t.integer           :target_id
      t.string            :target_type
      
      t.timestamps
    end
    
    add_index :events, :user_id
    add_index :events, :project_id
  end

  def self.down
    drop_table :events
  end
end

