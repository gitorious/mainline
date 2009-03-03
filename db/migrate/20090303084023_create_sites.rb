class CreateSites < ActiveRecord::Migration
  def self.up
    transaction do
      create_table :sites do |t|
        t.string  :title
        t.string  :subdomain
        t.timestamps
      end
      add_index :sites, :subdomain
      
      add_column :projects, :site_id, :integer
      add_index :projects, :site_id
    end
  end

  def self.down
    transaction do
      drop_table :sites
      remove_column :projects, :site_id
    end
  end
end
