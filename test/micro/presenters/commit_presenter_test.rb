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
require "commit_presenter"

class FakeGit
  attr_accessor :parents, :diffs

  def initialize(parents = [Object.new], diffs = [])
    @parents = parents
    @diffs = diffs
  end

  def commit(id)
    return nil if id == "0" * 40
    OpenStruct.new({
        :parents => parents,
        :diffs => diffs,
        :id => id,
        :to_patch => "Patch",
        :committer => OpenStruct.new(:email => "christian@gitorious.com"),
        :author => OpenStruct.new(:email => "christian@gitorious.com"),
      })
  end
end

class CommitPresenterTest < MiniTest::Spec
  before do
    @project = Project.new(:title => "My project")
    @git = FakeGit.new
    @repository = Repository.new(:project => @project, :git => @git)
  end

  describe "commit presenter" do
    before do
      @commit = CommitPresenter.new(@repository, "0123456789012345678901234567890123456789")
    end

    it "presents short oid" do
      assert_equal "0123456", @commit.short_oid
    end

    it "presents repository project" do
      assert_equal "My project", @commit.project.title
    end

    it "presents empty diffs array when no parents" do
      @git.parents = []
      assert_equal [], @commit.diffs
    end

    it "presents diffs if commit has parents" do
      @git.diffs = [{ id: 1 }, { id: 2 }]
      commit = CommitPresenter.new(@repository, "0123456789012345678901234567890123456789")
      assert_equal [{ id: 1 }, { id: 2 }], commit.diffs
    end

    it "presents raw diffs as a string" do
      @git.diffs = [OpenStruct.new(:diff => "Diff #1"), OpenStruct.new(:diff => "Diff #2")]
      commit = CommitPresenter.new(@repository, "0123456789012345678901234567890123456789")
      assert_equal "Diff #1\nDiff #2", commit.raw_diffs
    end

    it "does not exist if commit is nil" do
      commit = CommitPresenter.new(@repository, "0" * 40)
      assert !commit.exists?
    end

    it "presents patch" do
      assert_equal "Patch", @commit.to_patch
    end

    it "presents committer user" do
      user = Object.new
      User.expects(:find_by_email_with_aliases).with("christian@gitorious.com").returns(user)
      assert_equal user, @commit.committer_user
    end

    it "presents author user" do
      user = Object.new
      User.expects(:find_by_email_with_aliases).with("christian@gitorious.com").returns(user)
      assert_equal user, @commit.author_user
    end
  end
end
