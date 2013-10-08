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

class CreateCommitCommentTest < ActiveSupport::TestCase
  def setup
    @user = users(:zmalltalker)
    @repository = repositories(:johans)
  end

  should "create comment" do
    commit_id = "a" * 40
    outcome = CreateCommitComment.new(@user, @repository, commit_id).execute({
        :body => "Nice going!",
        :path => "some/thing.rb"
      })

    assert outcome.success?, outcome.to_s
    assert_equal Comment.last, outcome.result
    assert_equal "zmalltalker", outcome.result.user.login
    assert_equal "Nice going!", outcome.result.body
    assert_equal @repository, outcome.result.target
    assert_equal "a" * 40, outcome.result.sha1
    assert_equal "some/thing.rb", outcome.result.path
  end

  should "not create invalid comment" do
    commit_id = "a" * 40
    outcome = CreateCommitComment.new(@user, @repository, commit_id).execute({})

    refute outcome.success?, outcome.to_s
  end
end
