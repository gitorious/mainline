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
require "validators/new_user_validator"

class NewUserValidatorTest < MiniTest::Spec
  it "requires terms to be accepted" do
    result = NewUserValidator.call(User.new(:terms_of_use => false))
    refute_equal [], result.errors[:terms_of_use]
  end

  it "allows terms to be accepted" do
    result = NewUserValidator.call(User.new(:terms_of_use => true))
    assert_equal [], result.errors[:terms_of_use]
  end
end
