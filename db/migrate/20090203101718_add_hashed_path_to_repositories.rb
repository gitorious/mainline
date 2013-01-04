class AddHashedPathToRepositories < ActiveRecord::Migration
  def self.up
    transaction do
      add_column :repositories, :hashed_path, :string
      add_index :repositories, :hashed_path

      Repository.reset_column_information

      Repository.all.each do |repo|
        repo.update_attribute(:hashed_path, repo.send(:set_repository_hash))
      end
      say "\e[1;31m===> Now go and run script/shard_git_repositories_by_hash as the #{Gitorious.user} user <===\e[0m"
    end
  end

  def self.down
    remove_column :repositories, :hashed_path
  end
end
