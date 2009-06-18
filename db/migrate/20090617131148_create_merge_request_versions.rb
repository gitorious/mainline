class CreateMergeRequestVersions < ActiveRecord::Migration
  def self.up
    create_table :merge_request_versions do |t|
      t.integer :merge_request_id
      t.integer :version
      t.string :merge_base_sha
      t.timestamps
    end
  end

  def self.down
    drop_table :merge_request_versions
  end
end
