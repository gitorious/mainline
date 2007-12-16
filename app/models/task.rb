class Task < ActiveRecord::Base
  belongs_to :target, :polymorphic => true
  
  def self.find_all_pending
    find(:all, :conditions => {:performed => false})
  end
  
  def self.perform_all_pending!
    find_all_pending.each do |task|
      task.perform!
    end
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
