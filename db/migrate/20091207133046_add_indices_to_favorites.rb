class AddIndicesToFavorites < ActiveRecord::Migration
  def self.up
    add_index :favorites, [:watchable_type, :watchable_id, :user_id]
  end

  def self.down
    remove_index :favorites, [:watchable_type, :watchable_id, :user_id]
  end
end
