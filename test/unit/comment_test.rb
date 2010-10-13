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
      Message.destroy_all
    end

    should "be able to notify the creator of the target about a new comment" do
      comment = @merge_request.comments.new({
        :body => "need more cowbell",
        :project => projects(:johans)
      })
      comment.user = users(:johan)
      assert_difference("@merge_request.user.received_messages.count") do
        comment.save!
      end
      msg = @merge_request.user.received_messages.first
      assert_equal "johan commented on your merge request", msg.subject
    end

    should "not notify the target.user if it is the one who commented" do
      comment = @merge_request.comments.new({
        :body => "need more cowbell",
        :project => projects(:johans)
      })
      comment.user = @merge_request.user
      assert_no_difference("@merge_request.user.received_messages.count") do
        comment.save!
      end
    end

    should "notify creators about MergeRequestVersion comments as well" do
      @merge_request.build_new_version
      @merge_request.save!
      assert @merge_request.versions.count >= 1
      comment = @merge_request.versions.last.comments.new({
          :body => "off by one",
          :project => projects(:johans)
        })
      comment.user = users(:johan)
      assert_difference("@merge_request.user.received_messages.count") do
        comment.save!
      end
      msg = @merge_request.user.received_messages.first
      assert_equal "johan commented on your merge request", msg.subject
    end

    should "notify creators about MergeRequestVersion state changes" do
      @merge_request.build_new_version
      @merge_request.save!
      assert @merge_request.versions.count >= 1
      comment = @merge_request.versions.last.comments.new({
          :body => "off by one",
          :project => projects(:johans),
        })
      comment.state = "Huzzah"
      comment.user = users(:johan)
      assert_difference("@merge_request.user.received_messages.count") do
        comment.save!
      end
      msg = @merge_request.user.received_messages.first
      assert msg.body.include?("The status of your merge request is now Huzzah"), msg.body
    end
  end

  context "In general" do
    setup {@comment = Comment.new}

    should "not apply to specific line numbers" do
      assert !@comment.applies_to_line_numbers?
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
      assert !@merge_request.resolvable_by?(users(:moe))
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

  context "Editing" do
    setup {
      @user = users(:moe)
      @repo = repositories(:moes)
      @comment = @repo.comments.build({
          :user => @user,
          :body => "Nice try",
          :project => @repo.project
        })
      assert @comment.save
    }

    should "be editable for 10 minutes after being created" do
      assert @comment.creator?(@user)
      assert @comment.recently_created?
      assert @comment.editable_by?(@user)
    end

    should "not be editable when older than 10 minutes" do
      @comment.created_at = 9.minutes.ago
      assert @comment.editable_by?(@user)
      @comment.created_at = 11.minutes.ago
      assert !@comment.editable_by?(@user)
    end

    should "never be editable by other users than the creator" do
      assert !@comment.editable_by?(users(:mike))
    end
  end

  context 'On merge request versions' do
    setup do
      @merge_request = merge_requests(:moes_to_johans)
      @merge_request.stubs(:calculate_merge_base).returns("ffc00")
      @first_version = @merge_request.create_new_version
      @comment = @first_version.comments.build(:path => "README", :lines => "1-1:31-31+32",
        :sha1 => "ffac-aafc", :user => @merge_request.user,  :body => "Needs more cowbell",
        :project => @merge_request.target_repository.project)
      assert @comment.save!
    end

    should "have a target" do
      assert_equal @first_version, @comment.target
    end

    should "know if it has line numbers" do
      assert @comment.applies_to_line_numbers?
    end

    should "have a range of shas" do
      assert_equal(("ffac".."aafc"), @comment.sha_range)
      @comment.sha1 = "ffac"
      assert_equal(("ffac".."ffac"), @comment.sha_range)
    end

    should "have a range of lines" do
      assert_equal "1-1:31-31+32", @comment.lines
      assert_equal "1-1", @comment.first_line_number
      assert_equal "31-31", @comment.last_line_number
      assert_equal 32, @comment.number_of_lines
      @comment.lines = "2-3:2-3+0"
      assert_equal "2-3", @comment.first_line_number
      assert_equal "2-3", @comment.last_line_number
      assert_equal 0, @comment.number_of_lines
      assert_equal "2-3:2-3+0", @comment.lines
    end
  end

  context "On commits, with context" do
    setup do
      @target = repositories(:johans)
    end

    should "be commentable with path and line numbers" do
      comment = @target.comments.new(:body => "This is awesome", :user => users(:moe),
        :project => @target.project)
      comment.path = "README"
      comment.lines = "1-1:31-32+32"
      assert comment.save
      assert comment.applies_to_line_numbers?
    end
  end
end
