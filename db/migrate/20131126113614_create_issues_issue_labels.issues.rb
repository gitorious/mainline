# This migration comes from issues (originally 20131126113200)
class CreateIssuesIssueLabels < ActiveRecord::Migration
  def change
    create_table :issues_issue_labels do |t|
      t.integer :id
      t.integer :issue_id
      t.integer :label_id

      t.timestamps
    end

    add_index :issues_issue_labels, :issue_id
    add_index :issues_issue_labels, [:issue_id, :label_id], :unique => true
  end
end
