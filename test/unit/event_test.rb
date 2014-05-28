# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

require "test_helper"

class EventTest < ActiveSupport::TestCase
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

  should have_many(:feed_items).dependent(:destroy)

  should "belong to a user or have an author email" do
    event = Event.new(:target => repositories(:johans), :body => "blabla", :project => @project, :action => Action::COMMIT)
    assert event.user.nil?
    assert !event.valid?, "valid? should be false"
    event.email = "foo@bar.com"
    assert event.user.nil?
    assert event.valid?
    assert_equal "foo@bar.com", event.git_actor.email
  end

  should "belong to a user who commits with an aliased email" do
    event = Event.new(:target => repositories(:johans), :body => "blabla",
              :project => @project, :action => Action::COMMIT)
    assert_nil event.user
    event.email = emails(:johans1).address
    assert_equal users(:johan), event.user
  end

  should "handles setting the actor from a string" do
    event = Event.new
    event.email = "marius@stones.com"
    assert_equal "marius", event.actor_display
    event = Event.new
    event.email = "Marius Mathiesen <marius@stones.com>"
    assert_equal "Marius Mathiesen", event.actor_display
  end

  should "provides an actor_display for User objects too" do
    event = Event.new
    user = User.new(:fullname => "Johan Sørensen", :email => "johan@johansorensen.com")
    event.user = user
    assert_equal "Johan Sørensen", event.actor_display
  end

  context "A push event" do
    setup do
      @event = new_event(:action => Action::PUSH)
      assert @event.save
    end

    should "have a method for attaching commit events" do
      commit = @event.build_commit(
        :email  => "Linus Torvalds <linus@kernel.org>",
        :data   => "ffc0fa98",
        :body   => "Adding README")
      assert commit.save
      assert_equal(@event, commit.target)
      assert @event.has_commits?
      assert @event.events.commits.include?(commit)
      assert_equal("commit", commit.kind)
    end

    should "know if it has one or several commits" do
      commit = @event.build_commit(
        :email  => "Linus Torvalds <linus@kernel.org>",
        :data   => "ffc0fa98",
        :body   => "Adding README")
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

    should "return false for has_commits? unless it is a push event" do
      commit = @event.build_commit(
        :email  => "Linus Torvalds <linus@kernel.org>",
        :data   => "ffc0fa98",
        :body   => "Adding README")
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

  context "Notifications" do
    should "sends a notification to subscribed users" do
      event = new_event(action: Action::PUSH)

      EmailEventSubscribers.expects(:call).with(event)

      event.save!
    end
  end

  context "Archiving" do
    setup do
      @push_event = new_event(:action => Action::PUSH, :created_at => 32.days.ago)
      @commit_event = @push_event.build_commit(
        :email => "Linus Torvalds <linus@kernel.org",
        :data => "ffc099",
        :body => "Removing README",
        :created_at => 33.days.ago)
      @push_event.save
      @commit_event.save
    end

    should "have a class method for accessing events to be archived" do
      result = []
      Event.events_for_archive_in_batches(1.month.ago) do |batch|
        batch.each { |event| result << event}
      end
      assert_equal([@push_event], result)
    end

    should "include commits with Repository as target when archiving" do
      repository = repositories(:johans)
      initial_commit_event = new_event(
        :action => Action::PUSH,
        :created_at => 35.days.ago,
        :data => "ffc",
        :target => repository)
      initial_commit_event.save!
      result = []
      Event.events_for_archive_in_batches(1.month.ago) do |batch|
        batch.each {|event| result << event}
      end

      assert result.collect(&:id).include?(initial_commit_event.id)
    end

    should "not include newer events" do
      result = []
      Event.events_for_archive_in_batches(34.days.ago) do |batch|
        batch.each {|event| result << event}
      end
      assert !result.include?(@push_event)
    end

    should "have a class method for archiving events older than n days" do
      cutoff = 30.days.ago
      Event.expects(:events_for_archive_in_batches).yields([@push_event])
      @push_event.expects(:create_archived_event)
      @push_event.expects(:destroy)
      Event.archive_events_older_than(cutoff)
    end

    should "run in a transaction" do
      cutoff = 10.days.ago
      Event.expects(:transaction)
      Event.archive_events_older_than(cutoff)
    end

    should "create an archived event with our attributes, except id" do
      result = @push_event.create_archived_event
      result.attributes.reject{|k,v|k.to_sym == :id}.each do |name, value|
        assert_equal(value, @push_event.attributes[name], "#{name} should be #{value}")
      end
    end

    should "a push event should archive its commit events" do
      ArchivedEvent.delete_all
      result = @push_event.create_archived_event
      assert_equal 1, result.commits.size
    end

    should "destroy commit events when archived" do
      result = @push_event.create_archived_event
      assert_equal(0, @push_event.events.reload.size)
    end

    should "delete feed items when archiving events" do
      user = users(:mike)
      feed_item = FeedItem.create!(:event => @push_event, :watcher => user)
      @push_event.destroy
      assert_raises ActiveRecord::RecordNotFound do
        feed_item.reload
      end
    end
  end
end
