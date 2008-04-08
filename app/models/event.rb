class Event < ActiveRecord::Base
  belongs_to :action
  belongs_to :user
  belongs_to :target, :polymorphic => true
end
