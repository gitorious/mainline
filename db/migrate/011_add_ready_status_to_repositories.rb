class AddReadyStatusToRepositories < ActiveRecord::Migration
  def self.up
    add_column :repositories, :ready, :boolean
    add_index :repositories, :ready
  end

  def self.down
    remove_column :repositories, :ready
  end
end
