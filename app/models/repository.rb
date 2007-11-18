class Repository < ActiveRecord::Base
  belongs_to :user
  belongs_to :project
  
  validates_presence_of :user_id, :project_id
  validates_format_of :name, :with => /^[a-z0-9_\-]+$/i
end
