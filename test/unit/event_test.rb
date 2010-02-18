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

class EventTest < ActiveSupport::TestCase

  should_have_many :feed_items, :dependent => :destroy

  def setup
    @event = new_event
    @user = users(:johan)
    @repository = repositories(:johans)
    @project = @repository.project
  end

  def new_event(opts={})
    c = Event.new({
      :target => repositories(:johans),
      :body => "blabla"
    }.merge(opts))
    c.user = opts[:user] || users(:johan)
    c.project = opts[:project] || @project
    c
  end

  should " belong to a user or have an author email" do
    event = Event.new(:target => repositories(:johans), :body => 'blabla', :project => @project, :action => Action::COMMIT)
    assert event.user.nil?
    assert !event.valid?, 'valid? should be false'
    event.email = 'foo@bar.com'
    assert event.user.nil?
    assert event.valid?
    assert_equal 'foo@bar.com', event.git_actor.email
  end

  should "belong to a user who commits with an aliased email" do
    event = Event.new(:target => repositories(:johans), :body => 'blabla',
              :project => @project, :action => Action::COMMIT)
    assert_nil event.user
    event.email = emails(:johans1).address
    assert_equal users(:johan), event.user
  end

  should "handles setting the actor from a string" do
    event = Event.new
    event.email = "marius@stones.com"
    assert_equal 'marius', event.actor_display
    event = Event.new
    event.email = 'Marius Mathiesen <marius@stones.com>'
    assert_equal 'Marius Mathiesen', event.actor_display
  end

  should "provides an actor_display for User objects too" do
    event = Event.new
    user = User.new(:fullname => 'Johan Sørensen', :email => 'johan@johansorensen.com')
    event.user = user
    assert_equal 'Johan Sørensen', event.actor_display
  end

  context 'A push event' do
    setup do
      @event = new_event(:action => Action::PUSH)
      assert @event.save
    end

    should 'have a method for attaching commit events' do
      commit = @event.build_commit(
        :email  => 'Linus Torvalds <linus@kernel.org>',
        :data   => 'ffc0fa98',
        :body   => 'Adding README')
      assert commit.save
      assert_equal(@event, commit.target)
      assert @event.has_commits?
      assert @event.events.commits.include?(commit)
      assert_equal('commit', commit.kind)
    end

    should "know if it has one or several commits" do
      commit = @event.build_commit(
        :email  => 'Linus Torvalds <linus@kernel.org>',
        :data   => 'ffc0fa98',
        :body   => 'Adding README')
      assert commit.save
      assert_equal(@event, commit.target)
      assert @event.has_commits?
      assert @event.single_commit?
      second_commit = @event.build_commit(
        :email => "Linus Torvalds <linus@kernel.org>",
        :data => "ffc1fa98",
        :body => "Removing README")
      assert second_commit.save
      @event.reload
      assert @event.has_commits?
      assert !@event.single_commit?
    end

    should "return false for has_commits? unless it's a push event" do
      commit = @event.build_commit(
        :email  => 'Linus Torvalds <linus@kernel.org>',
        :data   => 'ffc0fa98',
        :body   => 'Adding README')
      assert commit.save
      @event.action = Action::COMMENT
      assert !@event.has_commits?
    end
  end

  context "Feeditem creation" do
    should "create feed items for all the watchers of the project and target" do
      users(:moe).favorites.create!(:watchable => @project)
      users(:mike).favorites.create!(:watchable => @repository)
      event = new_event(:action => Action::PUSH)

      assert_difference("FeedItem.count", 2) do
        event.save!
      end
      assert_equal event, users(:moe).feed_items.last.event
      assert_equal event, users(:mike).feed_items.last.event
    end

    should "not create a feed item for commit events" do
      users(:mike).favorites.create!(:watchable => @project)
      event = new_event(:action => Action::COMMIT)

      assert_no_difference("users(:mike).feed_items.count") do
        event.save!
      end
    end

    should "not notify users about their own events" do
      @user.favorites.create!(:watchable => @project)
      event = new_event(:action => Action::PUSH)
      assert_equal @user, event.user
      assert_no_difference("@user.feed_items.count") do
        event.save!
      end
    end
  end

  context "favorite notification" do
    setup do
      @event = new_event(:action => Action::PUSH)
      @favorite = users(:mike).favorites.new(:watchable => @repository)
      @favorite.notify_by_email = true
      @favorite.save!
    end

    should "find the favorites for the watchable with email notification turned on" do
      assert_equal [@favorite], @event.favorites_for_email_notification
      @favorite.update_attributes(:notify_by_email => false)
      assert_equal [], @event.favorites_for_email_notification
    end

    should "tell the Favorite instances with email notification to notify" do
      @event.expects(:favorites_for_email_notification).returns([@favorite])
      @favorite.expects(:notify_about_event).with(@event)
      @event.save!
    end

    should "not notify favorites if instructed not to" do
      @event.expects(:notify_about_event).never
      @event.disable_notifications { @event.notify_subscribers }
    end

    should "not notify favorites for commit events" do
      assert !@event.notifications_disabled?
      @event.action = Action::COMMIT
      assert @event.notifications_disabled?
    end

    should "check if notifications are disabled before sending notifications" do
      @event.expects(:notifications_disabled?)
      @event.notify_subscribers
    end
  end
end
