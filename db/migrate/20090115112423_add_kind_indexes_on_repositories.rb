class AddKindIndexesOnRepositories < ActiveRecord::Migration
  def self.up
    add_index :repositories, [:project_id, :kind]
  end

  def self.down
    remove_index :repositories, [:project_id, :kind]
  end
end
