class CreateFavorites < ActiveRecord::Migration
  def self.up
    create_table :favorites do |t|
      t.integer :user_id
      t.string :watchable_type
      t.integer :watchable_id
      t.string :action

      t.timestamps
    end
  end

  def self.down
    drop_table :favorites
  end
end
