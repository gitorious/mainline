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
require "change_password"

class ChangePasswordTest < ActiveSupport::TestCase
  should "change password for the current user" do
    user = users(:zmalltalker)
    outcome = ChangePassword.new(user).execute({
        :current_password => "test",
        :password => "tset",
        :password_confirmation => "tset",
        :actor => user
      })

    assert outcome.success?
    assert_equal user, outcome.result
    assert_equal user, User.authenticate(user.email, "tset")
  end

  should "change password without actor" do
    user = users(:zmalltalker)
    outcome = ChangePassword.new(user).execute({
        :current_password => "test",
        :password => "tset",
        :password_confirmation => "tset"
      })

    assert outcome.success?
  end

  should "refuse user to change other user's password" do
    user = users(:zmalltalker)
    outcome = ChangePassword.new(user).execute({
        :current_password => "test",
        :password => "tset",
        :password_confirmation => "tset",
        :actor => users(:moe)
      })

    assert outcome.pre_condition_failed?
  end

  should "refuse to change password if current password is wrong" do
    user = users(:zmalltalker)
    outcome = ChangePassword.new(user).execute({
        :current_password => "???",
        :password => "tset",
        :password_confirmation => "tset"
      })

    assert outcome.pre_condition_failed?
  end

  should "refuse to change password if passwords don't match" do
    user = users(:zmalltalker)
    outcome = ChangePassword.new(user).execute({
        :current_password => "test",
        :password => "++++",
        :password_confirmation => "----"
      })

    refute outcome.success?
    refute outcome.pre_condition_failed?
  end
end
