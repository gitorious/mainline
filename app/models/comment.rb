class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :repository
  belongs_to :project
  
  attr_protected :user_id
    
  validates_presence_of :user_id, :repository_id, :body, :project_id
  
  
end
