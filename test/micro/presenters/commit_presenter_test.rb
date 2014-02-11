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
  attr_accessor :parents, :diffs, :message

  def initialize(opts = {})
    @parents = opts[:parents] || [Object.new]
    @diffs = opts[:diffs] || []
    @message = opts[:message] || ""
  end

  def commit(id)
    return nil if id == "0" * 40
    OpenStruct.new({
        :message => message,
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

  describe "#exists?" do
    it "returns false if commit oid is invalid" do
      @git.stubs(:commit).with('totally-not-valid-sha') { raise RuntimeError, 'invalid string: nil' }
      @commit = CommitPresenter.new(@repository, 'totally-not-valid-sha')
      refute @commit.exists?
    end
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

  describe "#title" do
    def title_for_message(message)
      git = FakeGit.new(:message => message)
      repository = Repository.new(:project => @project, :git => git)
      commit = CommitPresenter.new(repository, "0123456789012345678901234567890123456789")
      commit.title
    end

    it "indicates empty commit message" do
      assert_equal "(empty commit message)", title_for_message("")
    end

    it "is single line if message is 1 line" do
      assert_equal "single line", title_for_message("single line")
    end

    it "trims lines longer than 72 chars" do
      assert_equal "x" * 69 + "...", title_for_message("x" * 73)
    end

    it "takes first line if message is multiline" do
      assert_equal "line one", title_for_message("line one\nline two")
    end

    it "takes first line of first paragraph if message is multi paragraph" do
      assert_equal "line one", title_for_message("line one\nline two\n\nsecond paragraph")
    end
  end

  describe "#description_paragraphs" do
    def paragraphs_for_message(message)
      git = FakeGit.new(:message => message)
      repository = Repository.new(:project => @project, :git => git)
      commit = CommitPresenter.new(repository, "0123456789012345678901234567890123456789")
      commit.description_paragraphs
    end

    it "is empty if message is blank" do
      assert_equal [], paragraphs_for_message("")
    end

    it "is empty if message is a single line" do
      assert_equal [], paragraphs_for_message("single line")
    end

    it "includes a paragraph with remaining title part" do
      assert_equal ["...xxxx"], paragraphs_for_message("x" * 73)
    end

    it "takes second line if message is multiline" do
      assert_equal ["line two"], paragraphs_for_message("line one\nline two")
    end

    it "takes all paragraphs except the first line if message is multi paragraph" do
      assert_equal ["line two\nline three", "second paragraph"], paragraphs_for_message("line one\nline two\nline three\n\nsecond paragraph")
    end
  end
end
