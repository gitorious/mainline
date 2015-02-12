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

class LdapGroupTest < ActiveSupport::TestCase
  def setup
    LdapGroup.any_instance.stubs(:validate_ldap_dns)
  end

  should validate_presence_of(:name)

  context "Ldap group serialization" do
    setup {
      @group = ldap_groups(:first_ldap_group)
      @group.member_dns = ["cn=testers","cn=developers"]
      @group.save
    }

    should "provide one membering DN per line" do
      assert_equal("cn=testers\ncn=developers", @group.ldap_group_names)
    end

    should "accept a newline separated list of member DNs" do
      @group.ldap_group_names = "cn=admin\ncn=developers"
      assert_equal(["cn=admin","cn=developers"], @group.member_dns)
    end

    should "handle legacy (string) list of member DNs" do
      @group.member_dns = "cn=testers \ncn=hackers"
      assert_equal(["cn=testers", "cn=hackers"], @group.member_dns)
    end

    should "handle legacy (nil) list of member DNs" do
      @group.member_dns = nil
      assert_equal([], @group.member_dns)
    end
  end

  context "Membership" do
    setup {
      @group = ldap_groups(:first_ldap_group)
      @user = users(:johan)
    }

    should "list filter LDAP groups which are known to us" do
      stub_ldap_groups(["cn=managers", "cn=admins","cn=developers"]) do
        assert_equal([@group], LdapGroup.groups_for_user(@user))
      end
    end

    should "list filter LDAP groups, ignoring letter case" do
      stub_ldap_groups(["cn=managers", "cn=admins","CN=developers"]) do
        assert_equal([@group], LdapGroup.groups_for_user(@user))
      end
    end

    should "return an empty list if no matches are found" do
      stub_ldap_groups(["cn=managers","cn=temps"]) do
        assert_equal([], LdapGroup.groups_for_user(@user))
      end
    end

    should "not try looking up memberships for anonymous users" do
      assert_equal([], LdapGroup.groups_for_user(nil))
    end
  end

  context "Owner prefix" do
    setup { @group = ldap_groups(:first_ldap_group) }

    should "use the + prefix" do
      assert_equal "+FirstLdapGroup", @group.to_param_with_prefix
    end
  end

  context "Deletion" do
    setup { @group = ldap_groups(:first_ldap_group) }

    should "be disallowed for groups owning projects" do
      p = projects(:johans)
      p.owner = @group
      assert p.save
      refute @group.deletable?
    end

    should "remove read-access to projects when deleted" do
      p = projects(:johans)
      p.content_memberships.create(:content => p, :member => @group)
      assert_incremented_by ContentMembership, :count, -1 do
        @group.destroy
      end
    end
  end

  context "Modifying memberships" do
    should "not be possible" do
      refute LdapGroup.new.memberships_modifiable_by?(User.new)
    end
  end

  context "LDAP filters" do
    setup do
      @group = ldap_groups(:first_ldap_group)
    end

    should "extract an LDAP filter" do
      assert_equal "(cn=admins)", @group.generate_ldap_filters_from_dn("cn=admins").to_s
    end

    should "extract an LDAP filter for two attributes" do
      assert_equal "(&(cn=admins)(ou=development))", @group.generate_ldap_filters_from_dn("cn=admins,ou=development").to_s
    end
  end

  context "Looking up members of a group" do
    setup do
      @group = ldap_groups(:first_ldap_group)
    end

    should "query each membering group for members" do
      LdapGroup.stubs(:ldap_configurator).returns(stub({
                                                         :members_attribute_name => "uniquemember",
                                                         :login_attribute => "cn"
                                                       }))
      LdapGroup.expects(:user_dns_in_group).with("cn=testers", "uniquemember").returns(["cn=johan"])
      LdapGroup.expects(:user_dns_in_group).with("cn=developers","uniquemember").returns([])
      assert_equal([users(:johan)], @group.members)
    end
  end

  context "Cache LDAP lookups" do
    should "by default not be cached" do
      group_name = "agroup"
      LdapGroup.expects(:ldap_configurator).returns(mock(:cache_expiry => 0))
      Rails.cache.expects(:fetch).with(["ldap_group", "members", group_name], :expires_in => 0.minutes).returns([])
      LdapGroup.user_dns_in_group(group_name, "memberof")
    end

    should "use specified interval in minutes" do
      group_name = "agroup"
      LdapGroup.expects(:ldap_configurator).returns(mock(:cache_expiry => 60))
      Rails.cache.expects(:fetch).with(["ldap_group", "members", group_name], :expires_in => 60.minutes).returns([])
      LdapGroup.user_dns_in_group(group_name, "memberof")
    end
  end

  def stub_ldap_groups(groups)
    LdapGroup.stubs(:ldap_group_names_for_user).returns(groups)
    LdapGroup.stubs(:ldap_configurator).returns(stub(:group_search_dn => nil))
    yield
  end
end
