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
    
  should_validate_presence_of :target, :user_id, :project_id
  
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
  
  context 'State change' do
    should 'be a list of previous and new state' do
      @merge_request = merge_requests(:moes_to_johans_open)
      @comment = @merge_request.comments.new(:body => 'PDI', :project => projects(:johans),
        :state_change => ['Before', 'After'])
      @comment.user = users(:johan)
      assert @comment.save
      assert_equal ['Before', 'After'], @comment.state_change
      assert_equal 'After', @merge_request.reload.status_tag.to_s
    end
    
    should 'change the state of its target' do
      @merge_request = merge_requests(:moes_to_johans_open)
      @comment = @merge_request.comments.new(:body => 'PDI', :project => projects(:johans))
      @comment.state = 'After'
      @comment.user = users(:johan)
      assert_equal @merge_request, @comment.target
      assert @comment.save!
      assert_equal 'After', @merge_request.reload.status_tag.to_s
    end

    should 'not change the state of its target unless the user can resolve it' do
      @merge_request = merge_requests(:moes_to_johans_open)
      @merge_request.update_attribute(:status_tag, 'Before')
      @comment = @merge_request.comments.new(:body => 'PDI', :project => projects(:johans))
      @comment.state = 'After'
      @comment.user = users(:moe)
      assert_equal ['Before', 'After'], @comment.state_change
      assert_equal 'After', @comment.state_changed_to
      assert @comment.save
      assert_equal 'Before', @merge_request.reload.status_tag.to_s
    end
    
    should 'know of previous and new states' do
      comment = Comment.new
      assert_nil comment.state_changed_from
      assert_nil comment.state_changed_to
      comment.state_change = ['Invalid']
      assert_nil comment.state_changed_from
      assert_equal 'Invalid', comment.state_changed_to
      comment.state_change = ['New', 'Closed']
      assert_equal 'New', comment.state_changed_from
      assert_equal 'Closed', comment.state_changed_to
    end

    should "not require a body if state changes" do
      @merge_request = merge_requests(:moes_to_johans_open)
      comment = @merge_request.comments.new(:project => projects(:johans),
        :user => users(:moe))
      assert comment.body_required?
      comment.state = "Foo"
      assert !comment.body_required?
      assert comment.save, "Should not require a body when state changes"
    end

    should "not update the state change if the previous state is the same" do
      @merge_request = merge_requests(:moes_to_johans_open)
      @merge_request.status_tag = "Foo"
      comment = @merge_request.comments.new(:project => projects(:johans),
        :user => users(:moe), :body => "just a comment")
      comment.state = "Foo"
      comment.save!
      assert_nil comment.reload.state_changed_from
      assert_nil comment.state_changed_to
    end
  end

  context 'On merge request versions' do
    setup do
      @merge_request = merge_requests(:moes_to_johans)
      @merge_request.stubs(:calculate_merge_base).returns("ffc00")
      @first_version = @merge_request.create_new_version
    end

    should "have a target" do
      comment = @first_version.comments.build(:path => "README", :lines => (1..33),
        :sha1 => "ffac-aafc", :user => @merge_request.user,  :body => "Needs more cowbell",
        :project => @merge_request.target_repository.project)
      assert comment.save!
      assert_equal 1, comment.first_line_number
      assert_equal 32, comment.number_of_lines
      assert_equal(("ffac".."aafc"), comment.sha_range)
      assert_equal @first_version, comment.target
    end
    
  end
end
