require 'test_helper'
require 'ldap_authentication'

class LdapAuthenticationTest < ActiveSupport::TestCase

  context 'Authenticating against LDAP server' do
    setup do
      @user = users(:johan)
      @ldap = mock()
      Net::LDAP.expects(:new).returns(@ldap)
      @ldap.stubs(:host=).once
      @ldap.stubs(:port=).once
      @ldap.stubs(:auth).once
      GitoriousConfig['ldap_host'] = "my.enterprise.ldap.box"
      GitoriousConfig['ldap_dn_template'] = 'cn=#{username},dc=example,dc=com'
    end

    should 'login user when authorized by LDAP server' do
      @ldap.stubs(:bind).returns(true)
      assert(@user.ldap_authenticated?(@user.password))
    end

    should 'not login user when rejected by LDAP server' do
      @ldap.stubs(:bind).returns(false)
      assert_equal(false, @user.ldap_authenticated?(@user.password))
    end

  end
end

