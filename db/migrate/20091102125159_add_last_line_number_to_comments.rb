class AddLastLineNumberToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :last_line_number, :string
  end

  def self.down
    add_column :comments, :last_line_number
  end
end
