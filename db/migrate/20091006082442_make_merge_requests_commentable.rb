class MakeMergeRequestsCommentable < ActiveRecord::Migration
  def self.up
    columns.each do |name, type|
      add_column :comments, name, type
    end
  end

  def self.down
    columns.each do |name, type|
      remove_column :comments, name
    end
  end

  def self.columns
    [
     [:path, :string],
     [:first_line_number, :integer],
     [:number_of_lines, :integer]
    ]
  end
end
