class MakeCommentsPolymorphic < ActiveRecord::Migration
  def self.up
    transaction do
      rename_column :comments, :repository_id, :target_id
      add_column :comments, :target_type, :string
      add_index :comments, [:target_id, :target_type]

      Comment.reset_column_information
      Comment.update_all("target_type = 'Repository'")
    end
  end

  def self.down
    rename_column :comments, :target_id, :repository_id
    remove_column :comments, :target_type
  end
end
