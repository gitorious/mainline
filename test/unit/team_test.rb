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

class TeamTest < ActiveSupport::TestCase
  def setup
    LdapGroup.any_instance.stubs(:validate_ldap_dns)
  end

  context "LDAP backend" do
    setup do
      @old_klass = Team.group_implementation
      Team.group_implementation = LdapGroup
    end

    teardown do
      Team.group_implementation = @old_klass
    end

    should "find by name" do
      assert_not_nil(Team.find_by_name!("FirstLdapGroup"))
    end

    should "return a new instance" do
      assert_kind_of LdapGroup, Team.new_group
    end

    should "create a new instance" do
      group = Team.create_group(ldap_group_params, User.first)
      assert_kind_of LdapGroup, group
    end

    should "return a group even if it's invalid" do
      name = "This is not valid"
      group = Team.create_group({:group => {:name => name}}, User.first)
      assert !group.valid?
      assert_equal name, group.name
    end

    should "destroy a group if user is admin" do
      assert_nothing_raised do
        group = ldap_groups(:first_ldap_group)
        Team.destroy_group(group.name, group.creator)
      end
    end

    should "not let others than the group creator destroy it" do
      assert_raises Team::DestroyGroupError do
        group = ldap_groups(:first_ldap_group)
        Team.destroy_group(group.name, users(:moe))
      end
    end

    should "treat group creator as admin" do
      group = ldap_groups(:first_ldap_group)
      user = group.creator
      assert Team.by_admin(user).include?(group)
    end

    should "find by id" do
      group = ldap_groups(:first_ldap_group)
      assert_equal group, Team.find(group.id)
    end
  end

  context "Group backend" do
    setup do
      @old_klass = Team.group_implementation
      Team.group_implementation = Group
    end

    teardown do
      Team.group_implementation = @old_klass
    end

    should "create a new instance" do
      group = Team.create_group(normal_group_params, User.first)
      assert group.valid?

    end

    should "list all groups for which a user is admin" do
      user = users(:johan)
      groups = user.groups.select{|g| admin?(user, g) }
      assert_equal groups, Team.by_admin(user)
    end

    should "find by id" do
      group = Group.first
      assert_equal(group, Team.find(group.id))
    end
  end

  context "Accessing groups" do
    setup {@group = groups(:a_team)}

    should "return events" do
      @group.expects(:events).returns([])
      Team.events(@group,nil)
    end

    should "return memberships" do
      assert_kind_of ActiveRecord::Relation, Team.memberships(@group)
    end
  end


  def ldap_group_params
    {:ldap_group => {:name => "Testing", :description => "4fun only"}}
  end

  def normal_group_params
    {:group => {:name => "Testing", :description => "4fun only"}}
  end
end
