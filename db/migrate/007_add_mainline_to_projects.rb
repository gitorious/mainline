class AddMainlineToProjects < ActiveRecord::Migration
  def self.up
    add_column  :repositories, :mainline, :boolean, :default => false
    add_column  :repositories, :parent_id, :integer
    add_index   :repositories, :parent_id
  end

  def self.down
    remove_column :repositories, :mainline
    remove_column :repositories, :parent_id
  end
end
