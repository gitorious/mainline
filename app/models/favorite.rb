class Favorite < ActiveRecord::Base
  belongs_to :user
  belongs_to :watchable, :polymorphic => true
  validates_presence_of :user_id, :watchable_id, :watchable_type
  validates_uniqueness_of :user_id, :scope => [:watchable_id, :watchable_type]
end
