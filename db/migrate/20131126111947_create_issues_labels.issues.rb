# This migration comes from issues (originally 20131126110305)
class CreateIssuesLabels < ActiveRecord::Migration
  def change
    create_table :issues_labels do |t|
      t.integer :id
      t.integer :project_id, :null => false
      t.string :name, :null => false
      t.string :color, :null => false

      t.timestamps
    end

    add_index :issues_labels, :project_id
    add_index :issues_labels, [:project_id, :name], :unique => true
  end
end
