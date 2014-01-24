class AddSuperGroupRemovedToRepositories < ActiveRecord::Migration
  def change
    add_column :repositories, :super_group_removed, :boolean, null: false, default: false
  end
end
