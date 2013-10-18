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

class MembershipValidatorTest < MiniTest::Spec
  it "validates presence of group, user and role" do
    result = MembershipValidator.call(Membership.new)

    refute result.valid?
    assert result.errors[:user]
    assert result.errors[:group]
    assert result.errors[:role]
  end

  it "requires uniq user" do
    membership = Membership.new(:user => User.new, :login => '', :group => Group.new, :role => Role.new)
    def membership.uniq?; false; end
    result = MembershipValidator.call(membership)

    refute result.valid?
    assert result.errors[:login]
  end

  it "passes validation" do
    membership = Membership.new(:user => User.new, :login => 'foo', :group => Group.new, :role => Role.new)
    def membership.uniq?; true; end

    assert MembershipValidator.call(membership).valid?
  end

  it "does not allow demotion of group creator" do
    creator = User.new
    group = Group.new(:creator => creator)
    membership = Membership.new(:user => creator, :login => '', :group => group, :role => Role.member)

    refute MembershipValidator.call(membership).valid?
  end
end
