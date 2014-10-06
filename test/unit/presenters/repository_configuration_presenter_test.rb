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

require "test_helper"

class RepositoryConfigurationPresenterTest < MiniTest::Spec
  let(:repository) { stub("repository", {
    id: 123,
    full_repository_path: "/repo/path.git",
    ssh_cloning?: true,
    http_cloning?: true,
    git_cloning?: true,
    ssh_clone_url: "git@host:project/repo.git",
    http_clone_url: "http://host/project/repo.git",
    git_clone_url: "git://host/project/repo.git",
  }) }

  let(:presenter) { RepositoryConfigurationPresenter.new(repository) }

  before do
    RepositoryHooks.stubs(:custom_hook_path).returns(nil)
  end

  describe "#as_json" do

    it "includes full_path" do
      assert_equal "/repo/path.git", presenter.as_json[:full_path]
    end

    it "includes repository id" do
      assert_equal 123, presenter.as_json[:id]
      assert_equal 123, presenter.as_json[:repository_id]
    end

    it "includes ssh_clone_url when ssh cloning enabled" do
      repository.expects(:ssh_cloning?).returns(true)
      assert_equal "git@host:project/repo.git", presenter.as_json[:ssh_clone_url]
    end

    it "doesn't include ssh_clone_url when ssh cloning disabled" do
      repository.expects(:ssh_cloning?).returns(false)
      assert_equal nil, presenter.as_json[:ssh_clone_url]
    end

    it "includes http_clone_url when http cloning enabled" do
      repository.expects(:http_cloning?).returns(true)
      assert_equal "http://host/project/repo.git", presenter.as_json[:http_clone_url]
    end

    it "doesn't include http_clone_url when http cloning disabled" do
      repository.expects(:http_cloning?).returns(false)
      assert_equal nil, presenter.as_json[:http_clone_url]
    end

    it "includes git_clone_url when git cloning enabled" do
      repository.expects(:git_cloning?).returns(true)
      assert_equal "git://host/project/repo.git", presenter.as_json[:git_clone_url]
    end

    it "doesn't include git_clone_url when git cloning disabled" do
      repository.expects(:git_cloning?).returns(false)
      assert_equal nil, presenter.as_json[:git_clone_url]
    end

    it "includes custom_pre_receive_path when hook exists" do
      RepositoryHooks.expects(:custom_hook_path).with("/repo/path.git", "pre-receive").returns("/the/path")
      assert_equal "/the/path", presenter.as_json[:custom_pre_receive_path]
    end

    it "doesn't include custom_pre_receive_path when hook doesn't exist" do
      RepositoryHooks.expects(:custom_hook_path).with("/repo/path.git", "pre-receive").returns(nil)
      assert_equal nil, presenter.as_json[:custom_pre_receive_path]
    end

    it "includes custom_post_receive_path when hook exists" do
      RepositoryHooks.expects(:custom_hook_path).with("/repo/path.git", "post-receive").returns("/the/path")
      assert_equal "/the/path", presenter.as_json[:custom_post_receive_path]
    end

    it "doesn't include custom_post_receive_path when hook doesn't exist" do
      RepositoryHooks.expects(:custom_hook_path).with("/repo/path.git", "post-receive").returns(nil)
      assert_equal nil, presenter.as_json[:custom_post_receive_path]
    end

    it "includes custom_update_path when hook exists" do
      RepositoryHooks.expects(:custom_hook_path).with("/repo/path.git", "update").returns("/the/path")
      assert_equal "/the/path", presenter.as_json[:custom_update_path]
    end

    it "doesn't include custom_update_path when hook doesn't exist" do
      RepositoryHooks.expects(:custom_hook_path).with("/repo/path.git", "update").returns(nil)
      assert_equal nil, presenter.as_json[:custom_update_path]
    end

  end
end
