# This migration comes from issues (originally 20131120190218)
class CreateIssuesIssues < ActiveRecord::Migration
  def change
    create_table :issues_issues do |t|
      t.integer :id
      t.string :state, :null => false
      t.integer :issue_id, :null => false
      t.integer :project_id, :null => false
      t.integer :user_id, :null => false
      t.string :title, :null => false
      t.text :description

      t.timestamps
    end

    add_index :issues_issues, [:issue_id, :project_id], :unique => true
    add_index :issues_issues, [:user_id, :project_id]
  end
end
