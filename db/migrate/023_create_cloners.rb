class CreateCloners < ActiveRecord::Migration
  def self.up
    create_table :cloners do |t|
      t.string :ip
      t.string :country_code, :length => 2
      t.string :country
      t.datetime :date
      t.integer :repository_id
    end
  end

  def self.down
    drop_table :cloners
  end
end

