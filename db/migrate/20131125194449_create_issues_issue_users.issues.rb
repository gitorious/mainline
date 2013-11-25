# This migration comes from issues (originally 20131122185628)
class CreateIssuesIssueUsers < ActiveRecord::Migration
  def change
    create_table :issues_issue_users do |t|
      t.integer :id
      t.integer :user_id, :null => false
      t.integer :issue_id, :null => false

      t.timestamps
    end

    add_index :issues_issue_users, :issue_id
    add_index :issues_issue_users, [:user_id, :issue_id], :unique => true
  end
end
