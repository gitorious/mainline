class AddLastMergeRequestSequenceNumberToRepositories < ActiveRecord::Migration
  def change
    add_column :repositories, :last_merge_request_sequence_number, :integer, null: false, default: 0

    execute "UPDATE repositories SET last_merge_request_sequence_number=(SELECT max(sequence_number) FROM merge_requests WHERE target_repository_id = repositories.id GROUP BY target_repository_id)"
  end
end
