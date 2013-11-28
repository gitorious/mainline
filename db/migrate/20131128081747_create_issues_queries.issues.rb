# This migration comes from issues (originally 20131128081452)
class CreateIssuesQueries < ActiveRecord::Migration
  def change
    create_table :issues_queries do |t|
      t.integer :id
      t.integer :user_id, :null => false
      t.integer :project_id, :null => false
      t.string :name, :null => false
      t.text :data, :null => false
      t.boolean :public, :default => false

      t.timestamps
    end

    add_index :issues_queries, :project_id
    add_index :issues_queries, [:user_id, :project_id]
    add_index :issues_queries, [:user_id, :project_id, :public]
  end
end
