class NukeCommitterships < ActiveRecord::Migration
  def self.up
    drop_table :committerships
  end

  def self.down
    create_table "committerships"
      t.integer  "user_id"
      t.integer  "repository_id"
      t.integer  "kind",          :default => 2
      t.datetime "created_at"
      t.datetime "updated_at"
    end
  end
end
