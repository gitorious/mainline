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
require "validators/comment_validators"

class CommentValidatorsTest < MiniTest::Spec
  it "validates presence of user, target, project" do
    result = CommentValidators::Basic.call(Comment.new)

    refute result.valid?
    assert result.errors[:user_id]
    assert result.errors[:target]
    assert result.errors[:project_id]
  end

  describe "commit comments" do
    it "requires body and commit id" do
      result = CommentValidators::Commit.call(Comment.new({
            :user_id => 1,
            :target => Repository.new,
            :project_id => 1
          }))

      refute result.valid?
      assert result.errors[:body]
      assert result.errors[:sha1]
    end

    it "requires commit id be a proper sha1 hash" do
      result = CommentValidators::Commit.call(Comment.new({
            :user_id => 1,
            :target => Repository.new,
            :project_id => 1,
            :sha1 => "01010101" # Too short
          }))

      refute result.valid?
      assert result.errors[:sha1]
    end

    it "approves valid comment" do
      result = CommentValidators::Commit.call(Comment.new({
            :user_id => 1,
            :target => Repository.new,
            :project_id => 1,
            :body => "Aight!",
            :sha1 => "0123456789abcdef0123456789abcdef01234567"
          }))

      assert result.valid?
    end
  end
end
