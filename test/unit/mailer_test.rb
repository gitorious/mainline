# encoding: utf-8
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


require File.dirname(__FILE__) + '/../test_helper'

class MailerTest < ActiveSupport::TestCase

  URL_BASE = "#{Mailer.default_url_options[:protocol]||'http'}://#{Mailer.default_url_options[:host]}"

  setup do
    Mailer.deliveries = []
  end

  should "send new_repository_clone" do
    repos = repositories(:johans2)
    url = "#{URL_BASE}/#{repos.project.to_param}/#{repos.to_param}"
    mail = Mailer.create_new_repository_clone(repos)

    assert_equal [repos.project.user.email], mail.to
    assert_equal %Q{[Gitorious] #{repos.user.login} has cloned #{repos.project.slug}/#{repos.parent.name}}, mail.subject
    assert_match(/#{repos.user.login} recently created a clone/, mail.body)
    assert mail.body.include?(url)

    Mailer.deliver(mail)
    assert_equal [mail], Mailer.deliveries
  end

  should "sends signup_notification" do
    user = users(:johan)
    user.password = "fubar"
    url = "#{URL_BASE}/users/activate/#{user.activation_code}"
    mail = Mailer.create_signup_notification(user)

    assert_equal [user.email], mail.to
    assert_equal "[Gitorious] Please activate your new account", mail.subject
    assert_match(/username is #{user.login}$/, mail.body)
    assert mail.body.include?(url)

    Mailer.deliver(mail)
    assert_equal [mail], Mailer.deliveries
  end

  should "sends activation" do
    user = users(:johan)
    mail = Mailer.create_activation(user)

    assert_equal [user.email], mail.to
    assert_equal "[Gitorious] Your account has been activated!", mail.subject
    assert_match(/your account has been activated/, mail.body)

    Mailer.deliver(mail)
    assert_equal [mail], Mailer.deliveries
  end

  should "sends merge_request_notification" do
    merge_request = merge_requests(:moes_to_johans)
    url = "#{URL_BASE}/#{merge_request.target_repository.project.to_param}/#{merge_request.target_repository.to_param}/merge_requests/#{merge_request.id}"
    mail = Mailer.create_merge_request_notification(merge_request)

    assert_equal [merge_request.target_repository.user.email], mail.to
    assert_equal "[Gitorious] moe has requested a merge in johans project", mail.subject
    assert_match(/moe has requested that you merge #{merge_request.source_repository.name} with #{merge_request.target_repository.name}/, mail.body)
    assert_match(/in the #{merge_request.target_repository.project.title} project/, mail.body)
    assert mail.body.include?(merge_request.proposal)
    assert mail.body.include?(url)

    Mailer.deliver(mail)
    assert_equal [mail], Mailer.deliveries
  end
  
  should "sends forgotten_password" do
    user = users(:johan)
    mail = Mailer.create_forgotten_password(user, "newpassword")
    
    assert_equal [user.email], mail.to
    assert_equal "[Gitorious] Your new password", mail.subject
    assert_match(/your new password is: newpassword/i, mail.body)
    
    Mailer.deliver(mail)
    assert_equal [mail], Mailer.deliveries
  end
  
  should "sends new_email_alias" do
    email = emails(:johans1)
    email.update_attribute(:confirmation_code, Digest::SHA1.hexdigest("borkborkbork"))
    mail = Mailer.create_new_email_alias(email)
    
    assert_equal [email.address], mail.to
    assert_equal "[Gitorious] Please confirm this email alias", mail.subject
    assert_match(/in order to activate your email alias/i, mail.body)
    assert_match(/#{email.confirmation_code}/, mail.body)
    
    Mailer.deliver(mail)
    assert_equal [mail], Mailer.deliveries
  end
  
  should 'send a notification of new messages' do
    recipient = users(:moe)
    sender = users(:mike)
    mail = Mailer.create_notification_copy(recipient, sender, "This is a message", "This is some text")
    assert_equal([recipient.email], mail.to)
    assert_match /#{sender.fullname} has sent you a message on Gitorious: /, mail.body
  end
end
