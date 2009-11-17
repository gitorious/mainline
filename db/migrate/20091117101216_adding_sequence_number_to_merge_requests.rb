class AddingSequenceNumberToMergeRequests < ActiveRecord::Migration
  def self.up
    add_column :merge_requests, :sequence_number, :integer
    execute("UPDATE merge_requests SET sequence_number=id")
  end

  def self.down
    remove_column :merge_requests, :sequence_number
  end
end
