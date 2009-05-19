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


require File.dirname(__FILE__) + '/../test_helper'

class CommentTest < ActiveSupport::TestCase
    
  should_validate_presence_of :target, :user_id, :body, :project_id
  
  context "message notifications" do
    setup do
      @merge_request = merge_requests(:moes_to_johans_open)
      @merge_request.user = users(:moe)
      @merge_request.save!
    end
    
    should "be able to notify the creator of the target about a new comment" do
      @comment = @merge_request.comments.new({
        :body => "need more cowbell",
        :project => projects(:johans)
      })
      @comment.user = users(:johan)
      assert_difference("@merge_request.user.received_messages.count") do
        @comment.save!
      end
    end
    
    should "not notify the target.user if it's the one who commented" do
      @comment = @merge_request.comments.new({
        :body => "need more cowbell",
        :project => projects(:johans)
      })
      @comment.user = @merge_request.user
      assert_no_difference("@merge_request.user.received_messages.count") do
        @comment.save!
      end
    end
  end
  
end
