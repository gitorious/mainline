class AddingStateChangeToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :state_change, :string
  end

  def self.down
    remove_column :comments,  :state_change
  end
end
