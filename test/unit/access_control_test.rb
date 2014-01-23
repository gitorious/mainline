# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

class AccessControlTest < ActiveSupport::TestCase
  context "Regular teams" do
    setup do
      @repository = repositories(:johans)
    end

    context "can_push?" do
      should "knows if a user can write to self" do
        @repository.owner = users(:johan)
        @repository.save!
        @repository.reload
        assert can_push?(users(:johan), @repository)
        assert !can_push?(users(:mike), @repository)

        @repository.change_owner_to!(groups(:team_thunderbird))
        @repository.save!
        assert !can_push?(users(:johan), @repository)

        @repository.owner.add_member(users(:moe), Role.member)
        @repository.committerships.reload
        assert can_push?(users(:moe), @repository)
      end
    end
  end

  context "LDAP backed groups" do
    setup do
      Team.group_implementation = LdapGroup
      @repository = repositories(:johans)
      @ldap_group = ldap_groups(:first_ldap_group)
      @committership = @repository.committerships.new_committership(:committer => @ldap_group)
      @committership.build_permissions(:commit)
      @user = users(:moe)
      LdapGroup.stubs(:ldap_group_names_for_user).returns(@ldap_group.member_dns)
      LdapGroup.stubs(:ldap_configurator).returns(stub(:group_search_dn => nil))
      @authorization = Gitorious::Authorization::DatabaseAuthorization.new
    end
    teardown do
      Team.group_implementation = Group
    end

    should "not grant push access without committership set up" do
      refute @authorization.can_push?(@user, @repository)
    end

    should "grant push access once committership exists" do
      LdapGroup.any_instance.stubs(:members).returns([])
      @committership.save!
      assert @authorization.can_push?(@user, @repository)
    end

    should "grant admin access to repositories" do
      @committership.build_permissions(:admin)
      @committership.save!
      assert @authorization.repository_admin?(@user, @repository)
    end

    should "let reviewers resolve merge requests" do
      @committership.build_permissions(:review)
      @committership.save!
      merge_request = @repository.merge_requests.build
      assert @authorization.can_resolve_merge_request?(@user, merge_request)
    end

    context "a user with direct access" do
      setup do
        @committership.committer = @user
        @committership.build_permissions :commit, :review, :admin
        @committership.save
      end

      should "grant push access to users with direct access" do
        assert @authorization.push_granted?(@repository, @user)
      end

      should "resolve merge request" do
        merge_request = @repository.merge_requests.build
        assert @authorization.can_resolve_merge_request?(@user, merge_request)
      end

      should "be repository admin" do
        assert @authorization.repository_admin?(@user, @repository)
      end
    end
  end
end
