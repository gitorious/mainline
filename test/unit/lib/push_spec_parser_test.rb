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
class PushSpecParserTest < ActiveSupport::TestCase

  context "Actions" do
    should "parse a tag creation" do
      spec = PushSpecParser.new(NULL_SHA, OTHER_SHA, "refs/tags/topic")

      assert spec.action_create?
      assert !spec.action_update?
      assert !spec.action_delete?
    end

    should "parse a tag update" do
      spec = PushSpecParser.new(SHA, OTHER_SHA, "refs/tags/topic")

      assert spec.action_update?
      assert !spec.action_create?
      assert !spec.action_delete?
    end

    should "parse a tag deletion" do
      spec = PushSpecParser.new(SHA, NULL_SHA, "refs/tags/topic")

      assert spec.action_delete?
      assert !spec.action_create?
      assert !spec.action_update?
    end
  end

  context "Refs" do
    should "recognize a tag" do
      spec = PushSpecParser.new(nil, nil, "refs/tags/topic")

      assert spec.tag?
      assert !spec.head?
      assert !spec.merge_request?
    end

    should "recognize a head" do
      spec = PushSpecParser.new(nil, nil, "refs/heads/master")

      assert spec.head?
      assert !spec.tag?
      assert !spec.merge_request?
    end

    should "recognize a merge request" do
      spec = PushSpecParser.new(nil, nil, "refs/merge-requests/1")

      assert spec.merge_request?
      assert !spec.head?
      assert !spec.tag?
    end

    should "recognize tag name" do
      spec = PushSpecParser.new(nil, nil, "refs/tags/topic")

      assert_equal "topic", spec.ref_name
    end

    should "recognize a branch with a slash in it" do
      spec = PushSpecParser.new(nil, nil, "refs/heads/release/0.5.0")
      assert_equal "release/0.5.0", spec.ref_name
    end
  end
end
