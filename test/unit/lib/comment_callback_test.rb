
# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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


require File.dirname(__FILE__) + '/../../test_helper'

class CommentCallbackTest < ActiveSupport::TestCase

  context "with several comments" do
    setup do
      @comments = [
                   Comment.new({
                       :lines => "1-1:1-3+2",
                       :body => "Hello",
                       :user => User.first
                     }),
                   Comment.new({
                       :lines => "1-1:1-1+0",
                       :body => "Single line",
                       :user => User.first
                     })
                  ]
      @callback = Gitorious::Diff::CommentCallback.new(@comments)
    end

    should "have a comment count for comments starting on a given line" do
      line = Diff::Display::AddLine.new("Yikes!", 1, false, [1,1])
      assert_equal 2, @callback.comment_count_starting_on_line(line)
    end

    should "have a comment count for comments ending on a given line" do
      line = Diff::Display::AddLine.new("Yikes!", 1, false, [1,3])
      assert_equal 1, @callback.comment_count_ending_on_line(line)
    end

    should "not raise if the Line does not implement the offsets" do
      line = Diff::Display::UnModLine.new("foo", 1, 1)
      assert_nothing_raised do
        @callback.comment_count_starting_on_line(line)
      end
      assert_nothing_raised do
        @callback.comment_count_ending_on_line(line)
      end
    end

    should "render comments for a given line" do
      template = stub
      template.expects(:render).with(:partial => "comments/inline_diff",
        :locals => {:comment => @comments.first})
      line = Diff::Display::AddLine.new("Yikes!", 2, false, [1,3])
      rendered = @callback.render_for(line, template)
    end
  end
end
