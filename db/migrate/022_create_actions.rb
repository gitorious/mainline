class CreateActions < ActiveRecord::Migration
  def self.up
    create_table :actions do |t|
      t.column :name, :string
    end
    add_index :actions, :name, :unique => true
    
    # On project
    Action.create :name => "create project"
    Action.create :name => "delete project"
    Action.create :name => "update project"
    Action.create :name => "fork project"
    
    # On repository
    Action.create :name => "commit"
    Action.create :name => "create branch"
    Action.create :name => "delete branch"
    Action.create :name => "create tag"
    Action.create :name => "delete tag"
    Action.create :name => "add committer"
    Action.create :name => "remove committer"
    Action.create :name => "comment"
    Action.create :name => "request merge"
    Action.create :name => "resolve merge request"
    Action.create :name => "update merge request"
    Action.create :name => "delete merge request"
  end

  def self.down
    drop_table :actions
  end
end

