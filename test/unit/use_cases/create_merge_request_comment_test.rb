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
require "create_merge_request_comment"

class CreateMergeRequestCommentTest < ActiveSupport::TestCase
  def setup
    @user = users(:zmalltalker)
    @repository = repositories(:johans)
    @merge_request = @repository.merge_requests.first
  end

  should "create comment" do
    outcome = CreateMergeRequestComment.new(@user, @merge_request).execute({
        :body => "Nice going!"
      })

    assert outcome.success?, outcome.to_s
    assert_equal Comment.last, outcome.result
    assert_equal "zmalltalker", outcome.result.user.login
    assert_equal "Nice going!", outcome.result.body
    assert_equal @merge_request, outcome.result.target
  end

  should "not create invalid comment" do
    outcome = CreateMergeRequestComment.new(@user, @merge_request).execute({})

    refute outcome.success?, outcome.to_s
  end

  should "create comment with only state change" do
    outcome = CreateMergeRequestComment.new(@merge_request.user, @merge_request).execute({
        :state => "Open"
      })

    assert outcome.success?, outcome.to_s
    assert_equal Comment.last, outcome.result
    assert_equal "Open", outcome.result.state_changed_to
    assert_equal nil, outcome.result.body
    assert_equal @merge_request, outcome.result.target
  end

  should "notify repository owner of merge request comment" do
    user = users(:moe)

    SendMessage.expects(:call).with(sender: user,
                                    recipient: @merge_request.user,
                                    subject: "moe commented on your merge request",
                                    body: "moe commented:\n\nNice work",
                                    notifiable: @merge_request)

    CreateMergeRequestComment.new(user, @merge_request).execute(body: "Nice work")
  end

  should "not notify repository owner of own comment" do
    assert_no_difference "Message.count" do
      outcome = CreateMergeRequestComment.new(@merge_request.user, @merge_request).execute({
          :body => "Aight"
        })
    end
  end

  should "update merge request status" do
    outcome = CreateMergeRequestComment.new(@merge_request.user, @merge_request).execute({
        :state => "Closed"
      })

    assert_equal "Closed", @merge_request.reload.status_tag.to_s
  end

  should "not allow non-owners to update status" do
    outcome = CreateMergeRequestComment.new(users(:moe), @merge_request).execute({
        :state => "Closed"
      })

    refute outcome.success, outcome.to_s
  end

  should "add to user's favorites" do
    user = users(:moe)
    assert_difference "user.favorites.count" do
      outcome = CreateMergeRequestComment.new(user, @merge_request).execute({
          :body => "Nice going!",
          :add_to_favorites => true
        })
    end

    assert @merge_request.watched_by?(user)
  end
end
