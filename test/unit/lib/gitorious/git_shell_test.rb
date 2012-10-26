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

class GitShellTest < ActiveSupport::TestCase
  context "Sanitization" do
    setup do
      @shell = Gitorious::GitShell.new
    end

    should "sanitize parameters sent to it" do
      @shell.expects(:sanitize).returns("")
      @shell.expects(:execute).returns(nil)
      @shell.graph_log(nil, nil)
    end

    should "remove anything but valid git object names" do
      input = "`id>/tmp/command`"
      assert_equal("id/tmp/command", @shell.sanitize(input))
    end
  end
end
