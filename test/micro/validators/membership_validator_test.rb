# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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
require "fast_test_helper"
require "validators/membership_validator"

class MembershipTest < MiniTest::Shoulda
  should "validate presence of group, user and role" do
    result = MembershipValidator.call(Membership.new)

    refute result.valid?
    assert result.errors[:user]
    assert result.errors[:group]
    assert result.errors[:role]
  end

  should "require uniq user" do
    membership = Membership.new(:user => User.new, :group => Group.new, :role => Role.new)
    def membership.uniq?; false; end
    result = MembershipValidator.call(membership)

    refute result.valid?
    assert result.errors[:user_id]
  end

  should "pass validation" do
    membership = Membership.new(:user => User.new, :group => Group.new, :role => Role.new)
    def membership.uniq?; true; end

    assert MembershipValidator.call(membership).valid?
  end

  should "not allow demotion of group creator" do
    creator = User.new
    group = Group.new(:creator => creator)
    membership = Membership.new(:user => creator, :group => group, :role => Role.member)

    refute MembershipValidator.call(membership).valid?
  end
end
