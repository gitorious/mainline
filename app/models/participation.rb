class Participation < ActiveRecord::Base
  belongs_to :group
  belongs_to :repository
  belongs_to :creator, :class_name => 'User'
  
  validates_presence_of :group_id, :repository_id
end
