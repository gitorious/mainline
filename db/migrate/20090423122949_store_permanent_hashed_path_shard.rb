class StorePermanentHashedPathShard < ActiveRecord::Migration
  def self.up
    transaction do
      Repository.find_each do |repo|
        repo.hashed_path = repo.send(:sharded_hashed_path, repo.hashed_path)
        repo.save!
      end
    end
  end

  def self.down
    transaction do
      Repository.find_each do |repo|
        repo.hashed_path = repo.hashed_path.gsub(/\//, '')
        repo.save!
      end
    end
  end
end
