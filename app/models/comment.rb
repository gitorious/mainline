class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :repository
  belongs_to :project
  
  is_indexed :fields => ["body"], :include => [{
      :association_name => "user",
      :field => "login",
      :as => "commented_by"
    }]
  
  attr_protected :user_id
    
  validates_presence_of :user_id, :repository_id, :body, :project_id
  
  
end
