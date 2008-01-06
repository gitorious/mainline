class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :repository
  
  attr_protected :user_id
    
  validates_presence_of :user_id, :repository_id, :body
  
  
end
