class AddProjectIdToComments < ActiveRecord::Migration
  def self.up
    add_column  :comments, :project_id, :integer
    add_index   :comments, :project_id
    ActiveRecord::Base::reset_column_information
    
    Comment.find(:all).each do |comment|
      comment.update_attributes(:project_id => comment.repository.project_id)
    end
  end

  def self.down
    remove_column :comments, :project_id
  end
end
