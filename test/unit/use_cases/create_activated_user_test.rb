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
require "create_activated_user"

class CreateActivatedUserTest < ActiveSupport::TestCase
  should "create user" do
    outcome = CreateActivatedUser.new.execute({
        :login => "cjohansen",
        :password => "pass",
        :password_confirmation => "pass",
        :email => "christian@gitorious.com"
      })

    assert_equal User.last, outcome.result
    assert outcome.success?, outcome.to_s
    assert_equal "cjohansen", outcome.result.login
    assert_nil outcome.result.activation_code
  end

  should "generate password if none is provided" do
    outcome = CreateActivatedUser.new.execute({
        :login => "cjohansen",
        :email => "christian@gitorious.com"
      })

    assert outcome.success?, outcome.to_s
    refute_nil outcome.result.password
  end

  should "not require new user to activate" do
    outcome = CreateActivatedUser.new.execute({
        :login => "cjohansen",
        :email => "christian@gitorious.com"
      })

    assert outcome.result.activated?
  end

  should "make new user admin" do
    outcome = CreateActivatedUser.new.execute({
        :login => "cjohansen",
        :email => "christian@gitorious.com",
        :is_admin => true
      })

    assert Gitorious::App.site_admin?(outcome.result)
  end
end
