# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 David Chelimsky <dchelimsky@gmail.com>
#   Copyright (C) 2008 Tim Dysinger <tim@dysinger.net>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
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
    @subject    += I18n.t "mailer.subject"
    @body[:url]  = url_for(
      :controller => 'users',
      :action => 'activate',
      :activation_code => user.activation_code
    )
  end

  def activation(user)
    setup_email(user)
    @subject    += I18n.t "mailer.activated"
  end

  def new_repository_clone(repository)
    setup_email(repository.project.user)
    @subject += I18n.t "mailer.repository_clone", :login => repository.user.login,
      :slug => repository.project.slug, :parent => repository.parent.name
    @body[:user] = repository.project.user
    @body[:cloner] = repository.user
    @body[:project] = repository.project
    @body[:repository] = repository
    @body[:url] =  project_repository_url(repository.project, repository)
  end

  def notification_copy(recipient, sender, subject, body, notifiable)
    @recipients       =  recipient.email
    @from             = "Gitorious <no-reply@#{GitoriousConfig['gitorious_host']}>"
    @subject          = subject
    @body[:recipient] = recipient.fullname
    @body[:url]       = "http://#{GitoriousConfig['gitorious_host']}/messages"
    @body[:body]      = body
    @body[:sender]    = sender.fullname
    if notifiable
      @body[:notifiable_url] = build_notifiable_url(notifiable) 
    end
  end

  def forgotten_password(user, password)
    setup_email(user)
    @subject += I18n.t "mailer.new_password"
    @body[:password] = password
  end
  
  def new_email_alias(email)
    @from       = "Gitorious <no-reply@#{GitoriousConfig['gitorious_host']}>"
    @subject    = "[Gitorious] Please confirm this email alias"
    @sent_on    = Time.now
    @recipients = email.address
    @body[:email] = email
    @body[:url] = confirm_user_email_url(email.user, email.confirmation_code)
  end

  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "Gitorious <no-reply@#{GitoriousConfig['gitorious_host']}>"
      @subject     = "[Gitorious] "
      @sent_on     = Time.now
      @body[:user] = user
    end
    
    def build_notifiable_url(a_notifiable)
      result = case a_notifiable
      when MergeRequest
        project_repository_merge_request_url(a_notifiable.target_repository.project, a_notifiable.target_repository, a_notifiable)        
      when Membership
        group_path(a_notifiable.group)
      end
      
      return result
    end
end
