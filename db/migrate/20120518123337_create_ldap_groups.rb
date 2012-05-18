class CreateLdapGroups < ActiveRecord::Migration
  def self.up
    create_table :ldap_groups do |t|
      t.string :name
      t.integer :user_id
      t.text :description
      t.string :avatar_file_name
      t.string :avatar_content_type
      t.string :avatar_file_size
      t.datetime :avatar_updated_at
      t.text :member_dns

      t.timestamps
    end
  end

  def self.down
    drop_table :ldap_groups
  end
end
