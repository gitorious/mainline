class ActsAsTaggableOnMigration < ActiveRecord::Migration
  def self.up
    change_table :taggings do |t|
      t.column :tagger_id, :integer
      t.column :tagger_type, :string
      t.column :context, :string
    end
  end
  
  def self.down
    remove_columns :taggings, :tagger_id, :tagger_type, :context
  end
end
