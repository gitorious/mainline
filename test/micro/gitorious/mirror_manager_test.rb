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

class GitoriousMirrorManagerTest < MiniTest::Spec
  before do
    Gitorious.executor.reset!
  end

  describe "init_repository" do
    it "execute the proper ssh command for each mirror" do
      mirrors = ["git@mirror1.gitorious.org", "git@mirror2.gitorious.org"]
      mirror_manager = Gitorious::MirrorManager.new(mirrors)
      repository = Repository.new(:real_gitdir => "foo/bar")

      mirror_manager.init_repository(repository)

      assert_equal "ssh git@mirror1.gitorious.org init foo/bar", Gitorious.executor.executed_commands.first
      assert_equal "ssh git@mirror2.gitorious.org init foo/bar", Gitorious.executor.executed_commands.last
    end
  end

  describe "clone_repository" do
    it "execute the proper ssh command for each mirror" do
      mirrors = ["git@mirror1.gitorious.org", "git@mirror2.gitorious.org"]
      mirror_manager = Gitorious::MirrorManager.new(mirrors)
      src_repository = Repository.new(:real_gitdir => "foo/bar")
      dst_repository = Repository.new(:real_gitdir => "baz/qux")

      mirror_manager.clone_repository(src_repository, dst_repository)

      assert_equal "ssh git@mirror1.gitorious.org clone foo/bar baz/qux", Gitorious.executor.executed_commands.first
      assert_equal "ssh git@mirror2.gitorious.org clone foo/bar baz/qux", Gitorious.executor.executed_commands.last
    end
  end

  describe "delete_repository" do
    it "execute the proper ssh command for each mirror" do
      mirrors = ["git@mirror1.gitorious.org", "git@mirror2.gitorious.org"]
      mirror_manager = Gitorious::MirrorManager.new(mirrors)

      mirror_manager.delete_repository("foo/bar")

      assert_equal "ssh git@mirror1.gitorious.org delete foo/bar", Gitorious.executor.executed_commands.first
      assert_equal "ssh git@mirror2.gitorious.org delete foo/bar", Gitorious.executor.executed_commands.last
    end
  end

  describe "push" do
    it "execute the proper ssh command for each mirror" do
      mirrors = ["git@mirror1.gitorious.org", "git@mirror2.gitorious.org"]
      mirror_manager = Gitorious::MirrorManager.new(mirrors)
      repository = Repository.new(:real_gitdir => "foo/bar", :full_repository_path => '/sth')

      mirror_manager.push(repository)

      assert_equal "cd /sth && git push --mirror git@mirror1.gitorious.org:foo/bar", Gitorious.executor.executed_commands.first
      assert_equal "cd /sth && git push --mirror git@mirror2.gitorious.org:foo/bar", Gitorious.executor.executed_commands.last
    end
  end
end
