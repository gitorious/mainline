class Mailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += 'Please activate your new account'
    @body[:url]  = "http://#{GitoriousConfig['gitorious_host']}/users/activate/#{user.activation_code}"
  
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
    @body[:url] = "http://#{GitoriousConfig['gitorious_host']}/p/#{repository.project.slug}/repos/#{repository.name}"
  end
  
  def merge_request_notification(merge_request)
    setup_email(merge_request.target_repository.user)
    @subject += %Q{#{merge_request.source_repository.user.login} has requested a merge in #{merge_request.target_repository.project.title}}
    @body[:merge_request] = merge_request
    @body[:project] = merge_request.target_repository.project
    url = "http://#{GitoriousConfig['gitorious_host']}/p/#{merge_request.target_repository.project.slug}"
    url << "/repos/#{merge_request.target_repository.name}"
    url << "/merge_requests/#{merge_request.id}"
    @body[:url] = url
  end
  
  def forgotten_password(user, password)
    setup_email(user)
    @subject += "Your new password"
    @body[:password] = password
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "Gitorious <no-reply@#{GitoriousConfig['gitorious_host']}>"
      @subject     = "[Gitorious] "
      @sent_on     = Time.now
      @body[:user] = user
    end
end
