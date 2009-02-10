class MakeUserIdOptionalInEvents < ActiveRecord::Migration
  def self.up
    change_column :events, :user_id, :integer, :null => true
    add_column :events, :user_email, :string
  end

  def self.down
    change_column :events, :user_id, :integer, :null => false
    remove_column :events, :user_email
  end
end
