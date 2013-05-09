# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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
require "generate_password_reset_token"

class GeneratePasswordResetTokenTest < ActiveSupport::TestCase
  should "fail without user" do
    outcome = GeneratePasswordResetToken.new(nil).execute

    refute outcome.success?, outcome.to_s
    assert outcome.pre_condition_failed?, outcome.to_s
  end

  should "fail with inactive user" do
    user = users(:zmalltalker)
    user.activation_code = "123456"
    user.save

    outcome = GeneratePasswordResetToken.new(user).execute

    refute outcome.success?, outcome.to_s
    refute outcome.pre_condition_failed?, outcome.to_s
  end

  should "generate password key and email it to the user" do
    count = ActionMailer::Base.deliveries.length
    outcome = GeneratePasswordResetToken.new(users(:zmalltalker)).execute

    refute_nil users(:zmalltalker).reload.password_key
    assert_equal count + 1, ActionMailer::Base.deliveries.length
    pattern = /reset your password\: http\:\/\/gitorious.test\/users\/reset_password\/[0-9a-f]+/
    assert_match pattern, ActionMailer::Base.deliveries.last.body.to_s
  end
end
