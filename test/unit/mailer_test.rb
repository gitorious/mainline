# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

  context 'Repository cloning notifications' do
    should "send notification with user URL for user repos" do
      repos = repositories(:johans_moe_clone)
      parent = repos.parent
      parent.user = users(:mike)
      parent.save!
      url = "#{URL_BASE}/~#{repos.owner.login}/#{repos.project.to_param}/#{repos.to_param}"
      mail = Mailer.create_new_repository_clone(repos)

      assert_equal [parent.user.email], mail.to
      assert_equal %Q{[Gitorious] #{repos.user.login} has cloned #{repos.parent.url_path}}, mail.subject
      assert_match(/#{repos.user.login} recently created a clone/, mail.body)
      assert mail.body.include?(url)

      Mailer.deliver(mail)
      assert_equal [mail], Mailer.deliveries
    end

    should "send notification with group URL for group repos" do
      repos = repositories(:johans2)
      url = "#{URL_BASE}/+#{repos.owner.name}/#{repos.project.to_param}/#{repos.to_param}"
      mail = Mailer.create_new_repository_clone(repos)

      assert_equal [repos.project.user.email], mail.to
      assert_equal %Q{[Gitorious] #{repos.user.login} has cloned #{repos.project.slug}/#{repos.parent.name}}, mail.subject
      assert_match(/#{repos.user.login} recently created a clone/, mail.body)
      assert mail.body.include?(url)
    end
  end


  should "sends signup_notification" do
    user = users(:johan)
    user.activation_code = "8f24789ae988411ccf33ab0c30fe9106fab32e9b"
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

  should "sends forgotten_password" do
    user = users(:johan)
    mail = Mailer.create_forgotten_password(user, "secret")
    
    assert_equal [user.email], mail.to
    assert_equal "[Gitorious] Your new password", mail.subject
    assert_match(/requested a new password for your/i, mail.body)
    assert_match(/reset your password: .+\/users\/reset_password\/secret/i, mail.body)
    
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
  
  should 'send a notification of new messages with a link to the message' do
    message_id = 99
    recipient = users(:moe)
    sender = users(:mike)
    merge_request = merge_requests(:moes_to_johans)
    mail = Mailer.create_notification_copy(recipient, sender, "This is a message", "This is some text", merge_request, message_id)
    assert_equal([recipient.email], mail.to)
    assert_match /#{sender.fullname} has sent you a message on Gitorious: /, mail.body
    assert_match /http:\/\/.*\/#{merge_request.target_repository.project.slug}\//i, mail.body
    assert_match "http://#{GitoriousConfig['gitorious_host']}/messages/#{message_id}", mail.body
  end
  
  should 'sanitize the contents of notifications' do
    recipient = users(:moe)
    sender = users(:mike)
    subject = %Q(<script type="text/javascript">alert(document.cookie)</script>Hello)
    body = %Q(<script type="text/javascript">alert('foo')</script>This is the actual message)
    mail = Mailer.create_notification_copy(recipient, sender, subject, body, nil, 9)
    assert_no_match /alert/, mail.body
    assert_no_match /document\.cookie/, mail.subject
    assert_match /Hello/, mail.subject
  end
end
