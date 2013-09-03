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
require "validators/password_validator"

class PasswordValidatorTest < MiniTest::Spec
  def assert_invalid(user)
    result = PasswordValidator.call(user)
    refute_equal [], result.errors[:password]
  end

  it "is valid when password and confirmation match" do
    user = User.new(:password => "foo1", :password_confirmation => "foo1")

    assert PasswordValidator.call(user).valid?
  end

  it "validates presence of password" do
    assert_invalid(User.new)
  end

  it "requires password confirmation" do
    user = User.new(:password => "heythere", :password_confirmation => "")
    assert_invalid(user)
  end

  it "validates that password is at least 4 characters long" do
    user = User.new(:password => "hey", :password_confirmation => "hey")
    assert_invalid(user)
  end
end
