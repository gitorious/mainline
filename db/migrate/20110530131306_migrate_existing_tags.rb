class MigrateExistingTags < ActiveRecord::Migration
  def self.up
    execute "update taggings set context='tags' where context IS NULL"
  end

  def self.down
  end
end
