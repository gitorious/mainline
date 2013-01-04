class RenameTroublesomeIndex < ActiveRecord::Migration
  def up
    rename_index "merge_requests", "index_merge_requests_on_sequence_number_and_target_repository_id", "index_merge_requests_on_sequence_number"
  end

  def down
    rename_index "merge_requests", "index_merge_requests_on_sequence_number", "index_merge_requests_on_sequence_number_and_target_repository_id"
  end
end
