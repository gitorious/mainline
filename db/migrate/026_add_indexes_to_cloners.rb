class AddIndexesToCloners < ActiveRecord::Migration
  def self.up
    add_index :cloners, :repository_id
    add_index :cloners, :date
    add_index :cloners, :ip
  end

  def self.down
    remove_index :cloners, :repository_id
    remove_index :cloners, :date
    remove_index :cloners, :ip
  end
end
