# This migration comes from issues (originally 20131122141753)
class CreateIssuesComments < ActiveRecord::Migration
  def change
    create_table :issues_comments do |t|
      t.integer :id
      t.integer :issue_id, :null => false
      t.integer :user_id, :null => false
      t.text :body, :null => false

      t.timestamps
    end

    add_index :issues_comments, :issue_id
  end
end
