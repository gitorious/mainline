class AddKindToRepository < ActiveRecord::Migration
  def self.up
    add_column :repositories, :kind, :integer, :default => 0
    add_index :repositories, :kind
  end

  def self.down
    remove_column :repositories, :kind
  end
end
