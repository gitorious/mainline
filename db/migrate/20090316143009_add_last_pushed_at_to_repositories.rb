class AddLastPushedAtToRepositories < ActiveRecord::Migration
  def self.up
    add_column :repositories, :last_pushed_at, :datetime
  end

  def self.down
    remove_column :repositories, :last_pushed_at
  end
end
