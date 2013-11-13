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
#
require "fast_test_helper"
require "gitorious/authorization/configuration"

class Gitorious::Authorization::DatabaseAuthorizationTest < MiniTest::Spec
  describe "comments" do
    let(:user) { User.new }
    let(:authorization) { Gitorious::Authorization::DatabaseAuthorization.new }
    let(:comment) { Comment.new(:user => user, :target => Project.new) }

    it "disallows edition of noneditable comments" do
      comment.stubs(:editable?).returns(false)
      comment.stubs(:creator?).with(user).returns(true)
      comment.stubs(:recently_created?).returns(true)

      refute authorization.can_edit_comment?(user, comment)
    end

    it "disallows edition of old comments" do
      comment.stubs(:editable?).returns(true)
      comment.stubs(:creator?).with(user).returns(true)
      comment.stubs(:recently_created?).returns(false)

      refute authorization.can_edit_comment?(user, comment)
    end

    it "disallows edition of other users comments" do
      comment.stubs(:editable?).returns(true)
      comment.stubs(:creator?).with(user).returns(false)
      comment.stubs(:recently_created?).returns(true)

      refute authorization.can_edit_comment?(user, comment)
    end

    it "allows for edition of recently added comments" do
      comment.stubs(:editable?).returns(true)
      comment.stubs(:creator?).with(user).returns(true)
      comment.stubs(:recently_created?).returns(true)

      assert authorization.can_edit_comment?(user, comment)
    end
  end
end
