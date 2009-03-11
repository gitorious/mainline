class MakeRepositoryHashUniqueIndex < ActiveRecord::Migration
  def self.up
    remove_index :repositories, :hashed_path
    add_index :repositories, :hashed_path, :unique => true
  end

  def self.down
    remove_index :repositories, :hashed_path
    add_index :repositories, :hashed_path
  end
end
