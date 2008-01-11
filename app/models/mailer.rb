class Mailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += 'Please activate your new account'
    @body[:url]  = "http://gitorious.org/users/activate/#{user.activation_code}"
  
  end
  
  def activation(user)
    setup_email(user)
    @subject    += 'Your account has been activated!'
  end
  
  def new_repository_clone(repository)
    setup_email(repository.project.user)
    @subject += %Q{#{repository.user.login} has cloned #{repository.project.slug}/#{repository.parent.name}}
    @body[:user] = repository.project.user
    @body[:cloner] = repository.user
    @body[:project] = repository.project
    @body[:repository] = repository
    @body[:url] = "http://gitorious.org/p/#{repository.project.slug}/repos/#{repository.name}"
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "Gitorious <no-reply@gitorious.org>"
      @subject     = "[Gitorious] "
      @sent_on     = Time.now
      @body[:user] = user
    end
end
