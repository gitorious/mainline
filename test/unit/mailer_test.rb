# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

require "test_helper"

class MailerTest < ActiveSupport::TestCase
  URL_BASE = "#{Mailer.default_url_options[:protocol]||'http'}://#{Mailer.default_url_options[:host]}"

  setup do
    Mailer.deliveries = []
  end

  should "sends signup_notification" do
    user = users(:johan)
    user.activation_code = "8f24789ae988411ccf33ab0c30fe9106fab32e9b"
    user.password = "fubar"
    url = "#{URL_BASE}/users/activate/#{user.activation_code}"
    mail = Mailer.signup_notification(user)

    assert_equal [user.email], mail.to
    assert_equal "[Gitorious] Please activate your new account", mail.subject
    assert_match(/username is #{user.login}$/, mail.body.decoded)
    assert mail.body.include?(url)
    assert_equal "auto-generated", mail["Auto-Submitted"].to_s

    mail.deliver
    assert_equal [mail], Mailer.deliveries
  end

  should "sends activation" do
    user = users(:johan)
    user.fullname = 'johan, bar'
    mail = Mailer.activation(user)

    assert_equal [user.email], mail.to
    assert_equal "[Gitorious] Your account has been activated!", mail.subject
    assert_match(/your account has been activated/i, mail.body.decoded)

    mail.deliver
    assert_equal [mail], Mailer.deliveries
  end

  should "sends forgotten_password" do
    user = users(:johan)
    mail = Mailer.forgotten_password(user, "secret")

    assert_equal [user.email], mail.to
    assert_equal "[Gitorious] Your password reset link", mail.subject
    body = mail.body.decoded
    assert_match(/requested a new password for your/i, body)
    assert_match(/reset your password: .+\/users\/reset_password\/secret/i, body)

    mail.deliver
    assert_equal [mail], Mailer.deliveries
  end

  should "sends new_email_alias" do
    email = emails(:johans1)
    email.update_attribute(:confirmation_code, Digest::SHA1.hexdigest("borkborkbork"))
    mail = Mailer.new_email_alias(email)

    assert_equal [email.address], mail.to
    assert_equal "[Gitorious] Please confirm this email alias", mail.subject
    assert_match(/in order to activate your email alias/i, mail.body.decoded)
    assert_match(/#{email.confirmation_code}/, mail.body.decoded)

    mail.deliver
    assert_equal [mail], Mailer.deliveries
  end

  should 'send a notification of new messages with a link to the message' do
    message_id = 99
    recipient = users(:moe)
    sender = users(:mike)
    merge_request = merge_requests(:moes_to_johans)
    mail = Mailer.notification_copy(recipient, sender, "This is a message", "This is some text", merge_request, message_id)
    assert_equal([recipient.email], mail.to)
    assert_equal "New message: This is a message", mail.subject

    body = mail.body.decoded
    assert_match /#{sender.fullname} has sent you a message on Gitorious:/, body
    assert_match /#{Gitorious.scheme}:\/\/.*\/#{merge_request.target_repository.project.slug}\//i, body
    assert_match Gitorious.url("/messages/#{message_id}"), body
  end

  should "sanitize the contents of notifications" do
    recipient = users(:moe)
    sender = users(:mike)
    subject = %Q(<script type="text/javascript">alert(document.cookie)</script>Hello)
    body = %Q(<script type="text/javascript">alert('foo')</script>This is the actual message)
    mail = Mailer.notification_copy(recipient, sender, subject, body, nil, 9)

    assert_no_match /alert/, mail.body.decoded
    assert_no_match /document\.cookie/, mail.subject
    assert_match /Hello/, mail.subject
  end

  should "send a favorite notification" do
    user = users(:mike)
    body = "some event notification data here "*10
    mail = Mailer.favorite_notification(user, body)

    assert_equal [user.email], mail.to
    assert_equal "[Gitorious] Activity: #{body[0..34]}...", mail.subject

    body = mail.body.decoded
    assert_match(/Hello #{user.login}/, body)
    assert mail.body.include?(body), "notification body not in: #{body}"
    assert_match(/you are receiving this email because/i, body)
    assert_match(/#{Gitorious.host}\/favorites/, body)
  end

  context "Sender address" do
    setup do
      @user = users(:moe)
    end

    should "be a sensible default unless configured" do
      Gitorious::Configuration.stubs(:configs).returns([])
      message = Mailer.signup_notification(@user)
      sender_address = "no-reply@#{Gitorious.host}"
      assert_equal sender_address, message.from.first
    end

    should "use configured sender address" do
      address = "Gitorious <no-reply@gitorious.example>"

      Gitorious::Configuration.override("email_sender" => address) do
        message = Mailer.signup_notification(@user)
        assert_equal "no-reply@gitorious.example", message.from.first
      end
    end
  end
end
