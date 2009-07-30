class CreateMergeRequestStatuses < ActiveRecord::Migration
  def self.up
    create_table :merge_request_statuses do |t|
      t.integer :project_id
      t.string  :name
      t.string  :color
      t.integer :state
      t.string  :description
      t.timestamps
    end
    add_index :merge_request_statuses, :project_id
    add_index :merge_request_statuses, [:project_id, :name]
  end

  def self.down
    drop_table :merge_request_statuses
  end
end
