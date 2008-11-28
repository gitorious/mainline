#--
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David Chelimsky <dchelimsky@gmail.com>
#   Copyright (C) 2008 Tim Dysinger <tim@dysinger.net>
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

class Mailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    += 'Please activate your new account'
    @body[:url]  = url_for(
      :controller => 'users',
      :action => 'activate',
      :activation_code => user.activation_code
    )
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
    @body[:url] =  project_repository_url(repository.project, repository)
  end

  def merge_request_notification(merge_request)
    setup_email(merge_request.target_repository.user)
    @subject += %Q{#{merge_request.source_repository.user.login} has requested a merge in #{merge_request.target_repository.project.title}}
    @body[:merge_request] = merge_request
    @body[:project] = merge_request.target_repository.project
    @body[:url] =
      project_repository_merge_request_url(
        merge_request.target_repository.project,
        merge_request.target_repository,
        merge_request
      )
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
