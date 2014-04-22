# encoding: utf-8
#--
#   Copyright (C) 2013-2014 Gitorious AS
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

class UserValidatorTest < MiniTest::Spec
  describe "macros" do
    before { @result = UserValidator.call(User.new) }

    it "validates presence of login" do
      refute_equal [], @result.errors[:login]
    end

    it "validates presence of email" do
      refute_equal [], @result.errors[:email]
    end

    it "validates presence of password" do
      refute_equal [], @result.errors[:password]
    end
  end

  describe "openid users" do
    before do
      @user = User.new(:identity_url => "http://my.local/identity")
      @result = UserValidator.call(@user)
    end

    it "validates presence of login" do
      refute_equal [], @result.errors[:login]
    end

    it "does not require password" do
      assert_equal [], @result.errors[:password]
      assert_equal [], @result.errors[:password_confirmation]
    end

    it "validates password length" do
      @user.password = "p"
      result = UserValidator.call(@user)
      assert_equal [], result.errors[:password]
      assert_equal [], result.errors[:password_confirmation]
    end
  end

  it "requires a login without spaces" do
    result = UserValidator.call(User.new(:login => "joe schmoe"))
    assert_equal ["is invalid"], result.errors[:login]

    result = UserValidator.call(User.new(:login => "joe_schmoe"))
    assert_equal [], result.errors[:login]

    result = UserValidator.call(User.new(:login => "joe-schmoe"))
    assert_equal [], result.errors[:login]

    result = UserValidator.call(User.new(:login => "joe.schmoe"))
    assert_equal [], result.errors[:login]
  end

  it "accepts short logins" do
    result = UserValidator.call(User.new(:login => "x"))
    assert_equal [], result.errors[:login]
  end

  it "requires an email that looks emailish" do
    result = UserValidator.call(User.new(:email => "kernel.wtf"))
    assert_equal 1, result.errors[:email].length
  end

  it "disallows email with new lines" do
    result = UserValidator.call(User.new(:email => "jane@doe.com\njane@doe.com"))
    assert_equal 1, result.errors[:email].length
  end

  it "allows emails with aliases and sub-domains" do
    result = UserValidator.call(new_user(:email => "ker+nel.w-t-f@foo-bar.co.uk"))
    assert result.valid?, result.errors.inspect
  end

  it "allows normalized identity urls" do
    user = new_user(:identity_url => "http://johan.somewhere.com")
    result = UserValidator.call(user)
    assert result.valid?, result.errors.inspect
  end

  it "disallows invalid identity_url" do
    user = new_user(:identity_url => "€&/()")
    def user.normalize_identity_url(url); raise "Invalid"; end
    refute UserValidator.call(user).valid?
  end

  it "requires unique login" do
    user = new_user
    def user.uniq_login?; false; end

    result = UserValidator.call(user)

    refute result.valid?
    refute_equal [], result.errors[:login]
  end

  it "requires unique email" do
    user = new_user
    def user.uniq_email?; false; end

    result = UserValidator.call(user)

    refute result.valid?
    refute_equal [], result.errors[:email]
  end

  it "requires password confirmation" do
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
