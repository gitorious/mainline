class AddingIndexToSequenceNumbers < ActiveRecord::Migration
  def self.up
    add_index :merge_requests, [:sequence_number, :target_repository_id], :unique => true
  end

  def self.down
    remove_index :merge_requests, :sequence_number
  end
end
