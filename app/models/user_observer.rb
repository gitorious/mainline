class UserObserver < ActiveRecord::Observer
  def after_create(user)
    Mailer.deliver_signup_notification(user)
  end

  def after_save(user)
    confirmation = (GitoriousConfig["require_confirmation"].nil? ? true : GitoriousConfig["require_confirmation"])
    Mailer.deliver_activation(user) if user.recently_activated? and confirmation
  
  end
end
