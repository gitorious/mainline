class AddingOauthPrefixToProject < ActiveRecord::Migration
  def self.up
    add_column :projects, :oauth_path_prefix, :string
  end

  def self.down
    remove_column :projects, :oauth_path_prefix
  end
end
