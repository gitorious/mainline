#--
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
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

require File.dirname(__FILE__) + '/../spec_helper'

describe Mailer do
  URL_BASE = "#{Mailer.default_url_options[:protocol]||'http'}://#{Mailer.default_url_options[:host]}"

  before(:each) do
    Mailer.deliveries = []
  end

  it "send new_repository_clone" do
    repos = repositories(:johans2)
    url = "#{URL_BASE}/projects/#{repos.project.slug}/repos/#{repos.name}"
    mail = Mailer.create_new_repository_clone(repos)

    mail.to.should == [repos.project.user.email]
    mail.subject.should == %Q{[Gitorious] #{repos.user.login} has cloned #{repos.project.slug}/#{repos.parent.name}}
    mail.body.should match(/#{repos.user.login} recently created a clone/)
    mail.body.should include(url)

    Mailer.deliver(mail)
    Mailer.deliveries.should == [mail]
  end

  it "sends signup_notification" do
    user = users(:johan)
    user.password = "fubar"
    url = "#{URL_BASE}/users/activate/#{user.activation_code}"
    mail = Mailer.create_signup_notification(user)

    mail.to.should == [user.email]
    mail.subject.should == "[Gitorious] Please activate your new account"
    mail.body.should match(/username is #{user.login}$/)
    mail.body.should include(url)

    Mailer.deliver(mail)
    Mailer.deliveries.should == [mail]
  end

  it "sends activation" do
    user = users(:johan)
    mail = Mailer.create_activation(user)

    mail.to.should == [user.email]
    mail.subject.should == "[Gitorious] Your account has been activated!"
    mail.body.should match(/your account has been activated/)

    Mailer.deliver(mail)
    Mailer.deliveries.should == [mail]
  end

  it "sends merge_request_notification" do
    merge_request = merge_requests(:moes_to_johans)
    url = "#{URL_BASE}/projects/#{merge_request.target_repository.project.slug}/repos/#{merge_request.target_repository.name}/merge_requests/#{merge_request.id}"
    mail = Mailer.create_merge_request_notification(merge_request)

    mail.to.should == [merge_request.target_repository.user.email]
    mail.subject.should == "[Gitorious] moe has requested a merge in johans project"
    mail.body.should match(/moe has requested that you merge #{merge_request.source_repository.name} with #{merge_request.target_repository.name}/)
    mail.body.should match(/in the #{merge_request.target_repository.project.title} project/)
    mail.body.should include(merge_request.proposal)
    mail.body.should include(url)

    Mailer.deliver(mail)
    Mailer.deliveries.should == [mail]
  end
  
  it "sends forgotten_password" do
    user = users(:johan)
    mail = Mailer.create_forgotten_password(user, "newpassword")
    
    mail.to.should == [user.email]
    mail.subject.should == "[Gitorious] Your new password"
    mail.body.should match(/your new password is: newpassword/i)
    
    Mailer.deliver(mail)
    Mailer.deliveries.should == [mail]
  end

end
