class UserObserver < ActiveRecord::Observer
  def after_create(user)
    Mailer.deliver_signup_notification(user)
  end

  def after_save(user)
    Mailer.deliver_activation(user) if user.recently_activated?  
  end
end
