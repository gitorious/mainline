class Task < ActiveRecord::Base
  belongs_to :target, :polymorphic => true
  
  def self.find_all_pending
    find(:all, :conditions => {:performed => false})
  end
  
  def self.perform_all_pending!(log=RAILS_DEFAULT_LOGGER)
    tasks_to_perform = find_all_pending
    log.info("Got #{tasks_to_perform.size.inspect} tasks to perform...")
    tasks_to_perform.each do |task|
      task.perform!(log)
    end
  end
  
  def perform!(log=RAILS_DEFAULT_LOGGER)
    transaction do
      log.info("Performing Task #{self.id.inspect}: #{target_class}::#{command}(#{arguments[0..64].inspect}..)")
      target_class.constantize.send(command, arguments)
      self.performed = true
      self.performed_at = Time.now
      save!
    end
  end
  
end
