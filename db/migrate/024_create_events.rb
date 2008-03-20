class CreateEvents < ActiveRecord::Migration
  def self.up
    create_table :events do |t|
      t.integer           :user_id, :null => false
      t.integer           :repository_id
      t.integer           :action_id, :null => false
      t.string            :ref
      t.text              :body
      t.datetime          :date, :null => false
    end
    
    add_index :events, :user_id
  end

  def self.down
    drop_table :events
  end
end
