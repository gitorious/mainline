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
require "create_merge_request_version_comment"

class CreateMergeRequestVersionCommentTest < ActiveSupport::TestCase
  def setup
    @mrv = MergeRequestVersion.first
    @merge_request = @mrv.merge_request
    @repository = @merge_request.target_repository
    @user = @merge_request.user
  end

  should "create comment" do
    outcome = CreateMergeRequestVersionComment.new(@user, @mrv).execute({
        :body => "Nice going!"
      })

    assert outcome.success?, outcome.to_s
    assert_equal Comment.last, outcome.result
    assert_equal "johan", outcome.result.user.login
    assert_equal "Nice going!", outcome.result.body
    assert_equal @mrv, outcome.result.target
  end

  should "not create invalid comment" do
    outcome = CreateMergeRequestVersionComment.new(@user, @mrv).execute({})

    refute outcome.success?, outcome.to_s
  end

  should "notify merge request owner of merge request version comment" do
    user = users(:moe)

    assert_difference "Message.count" do
      outcome = CreateMergeRequestVersionComment.new(user, @mrv).execute({
          :body => "Nice work"
        })
    end

    message = Message.last
    assert_equal user, message.sender
    assert_equal @merge_request.user, message.recipient
    assert_equal "moe commented on your merge request", message.subject
    assert_equal "moe commented:\n\nNice work", message.body
    assert_equal @mrv, message.notifiable
  end

  should "not notify merge request owner of own comment" do
    assert_no_difference "Message.count" do
      outcome = CreateMergeRequestVersionComment.new(@merge_request.user, @mrv).execute({
          :body => "Aight"
        })
    end
  end

  should "add merge_request to user's favorites" do
    user = users(:moe)
    assert_difference "user.favorites.count" do
      outcome = CreateMergeRequestVersionComment.new(user, @mrv).execute({
          :body => "Nice going!",
          :add_to_favorites => true
        })
    end

    assert @merge_request.watched_by?(user)
  end

  should "comment on diff" do
    range = ["0" * 40, "a" * 40].join("-")
    outcome = CreateMergeRequestVersionComment.new(@user, @mrv, range).execute({
        :body => "Nice going!",
        :context => "+ something",
        :path => "app/models/version.rb",
        :lines => "1-1:31-32+32"
      })

    assert outcome.success?, outcome.to_s
    assert_equal Comment.last, outcome.result
    assert_equal "johan", outcome.result.user.login
    assert_equal "Nice going!", outcome.result.body
    assert_equal "+ something", outcome.result.context
    assert_equal "app/models/version.rb", outcome.result.path
    assert_equal range, outcome.result.sha1
    assert_equal "1-1", outcome.result.first_line_number
    assert_equal @mrv, outcome.result.target
  end

  should "comment on a single commit" do
    outcome = CreateMergeRequestVersionComment.new(@user, @mrv, "a" * 40).execute({
        :body => "Nice going!",
        :context => "+ something",
        :path => "app/models/version.rb",
        :lines => "1-1:31-32+32"
      })

    assert outcome.success?, outcome.to_s
    assert_equal "a" * 40, outcome.result.sha1
  end

  should "not allow invalid ref spec" do
    range = ["a" * 40, "b" * 40, "c" * 40].join("-")
    outcome = CreateMergeRequestVersionComment.new(@user, @mrv, range).execute({
        :body => "Nice going!",
        :context => "+ something",
        :path => "app/models/version.rb",
        :lines => "1-1:31-32+32"
      })

    refute outcome.success?, outcome.to_s
  end
end
