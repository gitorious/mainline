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
require "fast_test_helper"
require "validators/user_validator"

class UserValidatorTest < MiniTest::Shoulda
  context "macros" do
    setup { @result = UserValidator.call(User.new) }

    should "validate presence of login" do
      refute_equal [], @result.errors[:login]
    end

    should "validate presence of email" do
      refute_equal [], @result.errors[:email]
    end

    should "validate presence of password" do
      refute_equal [], @result.errors[:password]
    end
  end

  context "openid users" do
    before do
      @user = User.new(:identity_url => "http://my.local/identity")
      @result = UserValidator.call(@user)
    end

    should "not require login" do
      assert_equal [], @result.errors[:login]
    end

    should "not require password" do
      assert_equal [], @result.errors[:password]
      assert_equal [], @result.errors[:password_confirmation]
    end

    should "validate password length" do
      @user.password = "p"
      result = UserValidator.call(@user)
      assert_equal [], result.errors[:password]
      assert_equal [], result.errors[:password_confirmation]
    end
  end

  should "require a login without spaces" do
    result = UserValidator.call(User.new(:login => "joe schmoe"))
    assert_equal ["is invalid"], result.errors[:login]

    result = UserValidator.call(User.new(:login => "joe_schmoe"))
    assert_equal [], result.errors[:login]

    result = UserValidator.call(User.new(:login => "joe-schmoe"))
    assert_equal [], result.errors[:login]

    result = UserValidator.call(User.new(:login => "joe.schmoe"))
    assert_equal [], result.errors[:login]
  end

  should "accept short logins" do
    result = UserValidator.call(User.new(:login => "x"))
    assert_equal [], result.errors[:login]
  end

  should "require an email that looks emailish" do
    result = UserValidator.call(User.new(:email => "kernel.wtf"))
    assert_equal 1, result.errors[:email].length
  end

  should "allow emails with aliases and sub-domains" do
    result = UserValidator.call(new_user(:email => "ker+nel.w-t-f@foo-bar.co.uk"))
    assert result.valid?, result.errors.inspect
  end

  should "allow normalized identity urls" do
    user = new_user(:identity_url => "http://johan.someprovider.com")
    assert UserValidator.call(user).valid?
  end

  should "disallow invalid identity_url" do
    user = new_user(:identity_url => "€&/()")
    def user.normalize_url(url); raise "Invalid"; end
    refute UserValidator.call(user).valid?
  end

  should "require unique login" do
    user = new_user(:identity_url => "€&/()")
    def user.uniq_login?; false; end

    result = UserValidator.call(user)

    refute result.valid?
    refute_equal [], result.errors[:login]
  end

  should "require password confirmation" do
    user = User.new(:password => "heythere", :password_confirmation => "")
    result = UserValidator.call(user)
    refute_equal [], result.errors[:password]
  end

  def new_user(params = {})
    User.new({
        :login => "zmalltalker",
        :email => "marius@gitorious.com",
        :password => "password",
        :password_confirmation => "password"
      }.merge(params))
  end
end
