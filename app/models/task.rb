class Task < ActiveRecord::Base
  serialize :arguments, Array
  
  def self.find_all_pending
    find(:all, :conditions => {:performed => false})
  end
  
  def self.perform_all_pending!(log=RAILS_DEFAULT_LOGGER)
    tasks_to_perform = find_all_pending
    log.debug("Got #{tasks_to_perform.size.inspect} tasks to perform...")
    tasks_to_perform.each do |task|
      task.perform!(log)
    end
  end
  
  def perform!(log=RAILS_DEFAULT_LOGGER)
    transaction do
      log.info("Performing Task #{self.id.inspect}: #{target_class}(#{target_id.inspect})::#{command}(#{arguments.inspect}..)")
      target_class.constantize.send(command, *arguments)
      self.performed = true
      self.performed_at = Time.now
      save!
      unless target_id.blank?
        obj = target_class.constantize.find_by_id(target_id)
        if obj && obj.respond_to?(:ready)
          obj.ready = true
          obj.save!
        end
      end
    end
  end
  
end
