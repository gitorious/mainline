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
require "create_commit_comment"
require "update_comment"

class UpdateCommentTest < ActiveSupport::TestCase
  def setup
    @user = users(:zmalltalker)
    @repository = repositories(:johans)
    @comment = CreateComment.new(@user, @repository).execute({
        :body => "Nice going!",
        :path => "some/thing.rb"
      }).result
  end

  should "update comment" do
    outcome = UpdateComment.new(@comment, @user).execute(:body => "Changing")

    assert outcome.success?, outcome.to_s
    assert_equal "Changing", outcome.result.body
    assert_equal @comment, outcome.result
  end

  should "not update invalid comment" do
    outcome = UpdateComment.new(@comment, @user).execute(:body => "")

    refute outcome.success?, outcome.to_s
  end

  should "not update other fields than body" do
    outcome = UpdateComment.new(@comment, @user).execute(:sha1 => "b" * 40)

    assert_nil @comment.reload.sha1
  end

  should "not update comment if no user" do
    outcome = UpdateComment.new(@comment, nil).execute(:sha1 => "b" * 40)

    refute outcome.success?
  end

  should "not update comment if user is not owner " do
    user = users(:johan)
    outcome = UpdateComment.new(@comment, user).execute(:sha1 => "b" * 40)

    refute outcome.success?
  end
end
