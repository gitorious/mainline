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
require "create_user"

class CreateUserTest < ActiveSupport::TestCase
  should "create user" do
    outcome = CreateUser.new.execute({
        :login => "cjohansen",
        :password => "pass",
        :password_confirmation => "pass",
        :terms_of_use => "1",
        :email => "christian@gitorious.com"
      })

    assert_equal User.last, outcome.result
    assert outcome.success?, outcome.to_s
    assert_equal "cjohansen", outcome.result.login
    refute_nil outcome.result.activation_code
  end

  should "fail user without password" do
    outcome = CreateUser.new.execute({
        :login => "cjohansen",
        :password => nil,
        :password_confirmation => "pass",
        :terms_of_use => "1",
        :email => "christian@gitorious.com"
      })

    refute outcome.success?
  end

  should "require new user to activate" do
    outcome = CreateUser.new.execute({
        :login => "cjohansen",
        :password => "pass",
        :password_confirmation => "pass",
        :terms_of_use => "1",
        :email => "christian@gitorious.com"
      })

    refute outcome.result.activated?
    assert_equal nil, User.authenticate("christian@gitorious.com", "pass")
  end
end
