class MergeRequestObserver < ActiveRecord::Observer
  
  def after_create(record)
    Mailer.deliver_merge_request_notification(record)
  end
  
end