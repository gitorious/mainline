class AddingPrivateRepositories < ActiveRecord::Migration
  def self.up
    add_column :repositories, :private, :boolean, :default => false
  end

  def self.down
    remove_column :repositories, :private
  end
end
