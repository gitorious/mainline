class AddDescriptionToRepositories < ActiveRecord::Migration
  def self.up
    add_column :repositories, :description, :text
  end

  def self.down
    remove_column :repositories, :description
  end
end
