class AddingProtocolToCloners < ActiveRecord::Migration
  def self.up
    add_column :cloners, :protocol, :string
    Cloner.reset_column_information
    Cloner.update_all(:protocol => 'git')
  end

  def self.down
    remove_column :cloners, :protocol
  end
end
