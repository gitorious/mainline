class CreateProjects < ActiveRecord::Migration
  def self.up
    create_table :projects do |t|
      t.column :name, :string
      t.column :description, :text
      t.column :user_id, :integer
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
    
    add_index :projects, :name
    add_index :projects, :user_id
  end

  def self.down
    drop_table :projects
  end
end
