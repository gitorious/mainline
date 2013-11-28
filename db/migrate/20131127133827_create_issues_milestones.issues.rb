# This migration comes from issues (originally 20131126135957)
class CreateIssuesMilestones < ActiveRecord::Migration
  def change
    create_table :issues_milestones do |t|
      t.integer :id
      t.integer :project_id, :null => false
      t.string :name, :null => false
      t.text :description
      t.date :due_date

      t.timestamps
    end

    add_index :issues_milestones, :project_id

    add_column :issues_issues, :milestone_id, :integer
    add_index :issues_issues, :milestone_id
  end
end
