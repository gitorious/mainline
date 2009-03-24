class AddingMergeRequestSignoffFields < ActiveRecord::Migration
  def self.up
    add_column :projects, :oauth_signoff_key, :string
    add_column :projects, :oauth_signoff_secret, :string
    add_column :projects, :oauth_signoff_site, :string
    
    add_column :merge_requests, :oauth_token, :string
    add_column :merge_requests, :oauth_secret, :string
    add_column :merge_requests, :contribution_agreement_version, :string
  end

  def self.down
    remove_column :projects, :oauth_signoff_key
    remove_column :projects, :oauth_signoff_secret
    remove_column :projects, :oauth_signoff_site
    
    remove_column :merge_requests, :oauth_token
    remove_column :merge_requests, :oauth_secret
    remove_column :merge_requests, :contribution_agreement_version
  end
end
