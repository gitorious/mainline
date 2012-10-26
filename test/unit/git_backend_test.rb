# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
#   Copyright (C) 2009 Johan Sørensen <johan@johansorensen.com>
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

require "tmpdir"
require "test_helper"

class GitBackendTest < ActiveSupport::TestCase

  def setup
    @repository = Repository.new({
      :name => "foo",
      :owner => projects(:johans),
      :user => users(:johan)
    })

    FileUtils.mkdir_p(@repository.full_repository_path, :mode => 0755)
  end

  should "creates a bare git repository" do
    path = @repository.full_repository_path
    FileUtils.expects(:mkdir_p).with(path, :mode => 0750).returns(true)
    FileUtils.expects(:touch).with(File.join(path, "git-daemon-export-ok"))

    GitBackend.expects(:execute_command).with(
      %Q{GIT_DIR="#{path}" git update-server-info}
    ).returns(true)

    GitBackend.create(path)
  end

  should "clones an existing repos into a bare one" do
    source_path = @repository.full_repository_path
    target_path = repositories(:johans).full_repository_path
    FileUtils.expects(:touch).with(File.join(target_path, "git-daemon-export-ok"))

    GitBackend.expects(:execute_command).with(
      %Q{GIT_DIR="#{target_path}" git update-server-info}
    ).returns(true)

    git = mock("Grit::Git instance")
    Grit::Git.expects(:new).returns(git)
    git.expects(:clone)

    GitBackend.clone(target_path, source_path)
  end

  should "deletes a git repository" do
    base_path = "/base/path"
    repos_path = base_path + "/repo"
    RepositoryRoot.expects(:default_base_path).returns(base_path)
    FileUtils.expects(:rm_rf).with(repos_path).returns(true)
    GitBackend.delete!(repos_path)
  end

  should "knows if a repos has commits" do
    path = @repository.full_repository_path
    dir_mock = mock("Dir mock")
    Dir.expects(:[]).with(File.join(path, "refs/heads/*")).returns(dir_mock)
    dir_mock.expects(:size).returns(0)
    assert !GitBackend.repository_has_commits?(path), 'GitBackend.repository_has_commits?(path) should be false'
  end

  should "knows if a repos has commits, if there is more than 0 heads" do
    path = @repository.full_repository_path
    dir_mock = mock("Dir mock")
    Dir.expects(:[]).with(File.join(path, "refs/heads/*")).returns(dir_mock)
    dir_mock.expects(:size).returns(1)
    assert GitBackend.repository_has_commits?(path), 'GitBackend.repository_has_commits?(path) should be true'
  end

end
