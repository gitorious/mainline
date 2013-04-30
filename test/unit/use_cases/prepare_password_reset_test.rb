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
require "test_helper"
require "reset_password"

class PreparePasswordResetTest < ActiveSupport::TestCase
  should "fail without user" do
    outcome = PreparePasswordReset.new(nil).execute

    refute outcome.success?, outcome.to_s
    assert outcome.pre_condition_failed?, outcome.to_s
  end

  should "succeed with user as result" do
    outcome = PreparePasswordReset.new(users(:zmalltalker)).execute

    assert outcome.success?
    assert_equal users(:zmalltalker), outcome.result
  end
end
