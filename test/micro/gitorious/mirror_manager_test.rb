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
require "gitorious/mirror_manager"

class GitoriousMirrorManagerTest < MiniTest::Shoulda
  def setup
    Gitorious.executor.reset!
  end

  context "init" do
    should "execute the proper ssh command for each mirror" do
      mirrors = ["git@mirror1.gitorious.org", "git@mirror2.gitorious.org"]
      mirror_manager = Gitorious::MirrorManager.new(mirrors)
      repository = Repository.new(:gitdir => "foo/bar")

      mirror_manager.init(repository)

      assert_equal "ssh git@mirror1.gitorious.org init foo/bar", Gitorious.executor.executed_commands.first
      assert_equal "ssh git@mirror2.gitorious.org init foo/bar", Gitorious.executor.executed_commands.last
    end
  end
end
