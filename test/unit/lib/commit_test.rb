# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
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

class CommitTest < ActiveSupport::TestCase
  context "Commits from registered users" do
    setup do
      @user = users(:moe)
      @committer = Grit::Actor.new("John Committer", @user.email)
      @author = Grit::Actor.new("Jane Author", "jane@g.org")
      @committed_at = 2.days.ago
      @body = "Awesome sauce"
      grit_commit = Grit::Commit.new(nil, "a"*40, [], nil,
        @author, 1.day.ago,
        @committer, @committed_at,
        [@body])
      @commit = Gitorious::Commit.new(grit_commit)
    end

    should "have an email" do
      assert_equal @user.email, @commit.email
    end

    should "find its user if email matches" do
      assert_equal @user, @commit.user
    end

    should "wrap its sha as data" do
      assert_equal "a"*40, @commit.data
    end

    should "have created_at" do
      assert_equal @committed_at, @commit.created_at
    end

    should "wrap its message as body" do
      assert_equal @body, @commit.body
    end

    should "have an actor display" do
      assert_equal "John Committer", @commit.actor_display
    end

    should "have its id mirror the sha" do
      assert_equal "a"*40, @commit.id
    end
  end

  context "Commits from non-gitorious users" do
    setup do
      @committer = Grit::Actor.new("John Committer", "noone@invalid.org")
      @author = Grit::Actor.new("Jane Author", "jane@g.org")
      grit_commit = Grit::Commit.new(nil, "a"*40, [], nil,
        @author, 1.day.ago,
        @committer, 2.days.ago,
        ["Awesome sauce"])
      @commit = Gitorious::Commit.new(grit_commit)
    end

    should "have an email" do
      assert_equal @committer.email, @commit.email
    end

    should "find its user if email matches" do
      assert_nil @commit.user
    end
  end

  context "Fetching commits for an event" do
    setup do
      @git = mock
      @event_id = 2
    end

    should "call commits_between" do
      @git.expects(:commits_between).with(SHA, OTHER_SHA).returns([])
      result = Gitorious::Commit.load_commits_between(@git, SHA, OTHER_SHA, @event_id)
    end

    should "be cached" do
      Rails.cache.expects(:fetch).with("commits_for_push_event_#{@event_id}").returns([])
      result = Gitorious::Commit.load_commits_between(@git, SHA, OTHER_SHA, @event_id)      
    end
  end
end
