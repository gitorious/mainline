require 'test_helper'

class LdapGroupTest < ActiveSupport::TestCase
  context "Ldap group serialization" do
    setup {
      @group = ldap_groups(:first_ldap_group)
      @group.member_dns = ["cn=admins","cn=developers"]
      @group.save
    }

    should "provide one membering DN per line" do
      assert_equal("cn=admins\ncn=developers", @group.ldap_group_names)
    end

    should "accept a newline separated list of member DNs" do
      @group.ldap_group_names = "cn=admin\ncn=developers"
      assert_equal(["cn=admin","cn=developers"], @group.member_dns)
    end
  end
end
