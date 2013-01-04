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

class RoleTest < ActiveSupport::TestCase

  should "know if it is an admin" do
    assert roles(:admin).admin?, 'roles(:admin).admin? should be true'
    assert !roles(:admin).member?
  end

  should "know if it is a committer" do
    assert roles(:member).member?
    assert !roles(:member).admin?
  end

  should "gets the admin role object" do
    assert_equal roles(:admin), Role.admin
  end

  should "gets the committer object" do
    assert_equal roles(:member), Role.member
  end

  context 'Comparing roles' do
    should 'know if a role is "higher" than another role' do
      assert roles(:member) < roles(:admin)
      assert roles(:admin) > roles(:member)
      assert roles(:admin) == roles(:admin)
    end
  end
end
