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
require "validators/nil_validator"

class NilValidatorTest < MiniTest::Spec
  it "passes when subject is not nil" do
    result = NilValidator.new("Ouch").call(Object.new)
    assert result.valid?
  end

  it "fails with messagewhen subject is nil" do
    result = NilValidator.new("Ouch").call(nil)
    refute result.valid?
    assert_equal ["Ouch"], result.errors
  end
end
