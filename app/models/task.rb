class Task < ActiveRecord::Base
  belongs_to :target, :polymorphic => true
  
  def self.find_all_to_perform
    find(:all, :conditions => {:performed => false})
  end
  
  def perform!
    transaction do
      target.send(command)
      self.performed = true
      self.performed_at = Time.now
      save!
    end
  end
  
end
