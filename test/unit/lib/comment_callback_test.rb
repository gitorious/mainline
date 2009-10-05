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
  context "A single commit" do
    setup do
      comment = stub(:lines => (1..2), :body => "Nice work")
      @callback = Gitorious::Diff::CommentCallback.new(Array(comment))
    end
    
    should "render nothing if the line is out of range" do
      line = Diff::Display::AddLine.new("Hello", 3)
      assert_equal %Q{<td class="blue comment none"></td>}, @callback.line(line)
    end


    should "render a hint when a line is within range" do
      line = Diff::Display::AddLine.new("Hello", 1)
      assert_equal %Q{<td class="blue comment first"></td>}, @callback.line(line)
    end

    should "render a hint and the comment on the last line" do
      line = Diff::Display::AddLine.new("Hello", 2)      
      assert_equal %Q{<td class="blue comment last"></td>}, @callback.line(line)
    end
  end

  context "with several comments" do
    setup do
      comments = [
                  stub(:lines => (1..2), :body => "Hello"),
                  stub(:lines => (1..1), :body => "Single line")
                 ]
      @callback = Gitorious::Diff::CommentCallback.new(comments)
    end

    should "render each comment inline when within range" do
      line = Diff::Display::AddLine.new("Yikes!", 1)
      assert_match /<td.*>.*<\/td>\s?<td.*>.*<\/td>/, @callback.line(line)
    end
  end
end
