class CreateProjectProposals < ActiveRecord::Migration
  def self.up
    create_table :project_proposals do |t|
      t.string :title
      t.text :description
      t.integer   :user_id
      t.timestamps
    end
  end

  def self.down
    drop_table :project_proposals
  end
end
