class AddEditableToComments < ActiveRecord::Migration
  def change
    add_column :comments, :editable, :boolean, :default => 1
  end
end
