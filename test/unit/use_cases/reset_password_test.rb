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
require "reset_password"

class ResetPasswordTest < ActiveSupport::TestCase
  should "fail without user" do
    outcome = ResetPassword.new(nil).execute

    refute outcome.success?, outcome.to_s
    assert outcome.pre_condition_failed?, outcome.to_s
  end

  should "fail if passwords don't match" do
    outcome = ResetPassword.new(users(:zmalltalker)).execute({
        :password => "a",
        :password_confirmation => "b"
      })

    refute outcome.success?, outcome.to_s
    refute outcome.pre_condition_failed?, outcome.to_s
  end

  should "fail if there's no password" do
    outcome = ResetPassword.new(users(:zmalltalker)).execute

    refute outcome.success?, outcome.to_s
    refute outcome.pre_condition_failed?, outcome.to_s
  end

  should "update password" do
    zt = users(:zmalltalker)

    outcome = ResetPassword.new(zt).execute({
        :password => "heyheyhey",
        :password_confirmation => "heyheyhey"
      })

    assert outcome.success?
    assert_equal zt, User.authenticate(zt.email, "heyheyhey")
  end
end
