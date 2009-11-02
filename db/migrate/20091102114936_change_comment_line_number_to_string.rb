class ChangeCommentLineNumberToString < ActiveRecord::Migration
  def self.up
    change_column :comments, :first_line_number, :string
  end

  def self.down
    change_column :comments, :first_line_number, :integer
  end
end
