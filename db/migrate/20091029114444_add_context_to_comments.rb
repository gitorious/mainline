class AddContextToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :context, :text
  end

  def self.down
    remove_column :comments, :context
  end
end
