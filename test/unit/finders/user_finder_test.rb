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
require "user_finder"

class UserFinderTest < ActiveSupport::TestCase
  should "find user by login" do
    user = users(:moe)
    assert_equal user, UserFinder.new.by_login(user.login)
  end

  should "find user by id" do
    user = users(:moe)
    assert_equal user, UserFinder.new.by_id(user.id)
  end
end
