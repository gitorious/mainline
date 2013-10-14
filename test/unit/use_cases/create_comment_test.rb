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
require "create_comment"

class CreateCommentTest < ActiveSupport::TestCase
  def setup
    @user = users(:zmalltalker)
    @repository = repositories(:johans)
  end

  should "create comment" do
    outcome = CreateComment.new(@user, @repository).execute({
        :body => "Nice going!"
      })

    assert outcome.success?, outcome.to_s
    assert_equal Comment.last, outcome.result
    assert_equal "zmalltalker", outcome.result.user.login
    assert_equal "Nice going!", outcome.result.body
    assert_equal @repository, outcome.result.target
  end

  should "not create invalid comment" do
    outcome = CreateComment.new(@user, @repository).execute({})

    refute outcome.success?, outcome.to_s
  end

  should "create merge request comment" do
    outcome = CreateComment.new(@user, MergeRequest.first).execute({
        :body => "Nice going!"
      })

    assert outcome.success?, outcome.to_s
    assert_equal Comment.last, outcome.result
    assert_equal "zmalltalker", outcome.result.user.login
    assert_equal "Nice going!", outcome.result.body
    assert_equal MergeRequest.first, outcome.result.target
  end

  should "create new comment event" do
    outcome = CreateComment.new(@user, @repository).execute({ :body => "Nice going!" })
    event = @repository.project.events.last

    assert_equal Action::COMMENT, event.action
    assert_equal @user, event.user
    assert_equal event.data, outcome.result.id.to_s
    assert_equal "Repository", event.body
    assert_equal @repository.project, event.project
    assert_equal @repository, event.target
  end
end
