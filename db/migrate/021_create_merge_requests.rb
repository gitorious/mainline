class CreateMergeRequests < ActiveRecord::Migration
  def self.up
    create_table :merge_requests do |t|
      t.integer   :user_id
      t.integer   :source_repository_id
      t.integer   :target_repository_id
      t.text      :proposal
      t.string    :sha_snapshot
      t.integer   :status, :default => 0
      t.timestamps
    end
    add_index :merge_requests, :user_id
    add_index :merge_requests, :source_repository_id
    add_index :merge_requests, :target_repository_id
    add_index :merge_requests, :status
  end

  def self.down
    drop_table :merge_requests
  end
end
