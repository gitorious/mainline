# encoding: utf-8
#--
#   Copyright (C) 2014 Gitorious AS
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
require "commands/destroy_membership_command"

class DestroyMembershipCommandTest < MiniTest::Spec
  before do
    @membership = Membership.new
    @command = DestroyMembershipCommand.new(@membership)
  end

  describe "#execute" do
    it "creates repository" do
      @membership.expects(:destroy)
      @command.execute({})
    end
  end
end
