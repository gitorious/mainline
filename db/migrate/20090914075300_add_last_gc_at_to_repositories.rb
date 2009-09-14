class AddLastGcAtToRepositories < ActiveRecord::Migration
  def self.up
    add_column :repositories, :last_gc_at, :datetime
  end

  def self.down
    remove_column :repositories, :last_gc_at
  end
end
