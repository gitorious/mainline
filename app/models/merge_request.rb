class MergeRequest < ActiveRecord::Base
  belongs_to :user
  belongs_to :source_repository, :class_name => 'Repository'
  belongs_to :target_repository, :class_name => 'Repository'
  
  validates_presence_of :user, :source_repository, :target_repository
  attr_protected :user_id
end
