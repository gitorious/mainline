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

class EmailEventSubscribersTest < ActiveSupport::TestCase
  context ".call" do
    include MessagingTestHelper

    should "schedule an EventMailer job" do
      event = Event.new
      event.id = 3
      EmailEventSubscribers.call(event)

      queue_messages = Gitorious::Messaging::TestAdapter.messages_on(EmailEventSubscribers::QUEUE)
      assert_equal({"event_id" => 3}, queue_messages.last)
    end
  end

  context ".users_to_notify" do
    should "not return the user that triggered the event" do
      moe = users(:moe)
      mike = users(:mike)
      zmalltalker = users(:zmalltalker)

      repository = repositories(:johans)
      project = repository.project

      Favorite.create!(user: moe, watchable: repository, notify_by_email: true)
      Favorite.create!(user: mike, watchable: repository, notify_by_email: true)
      Favorite.create!(user: zmalltalker, watchable: repository, notify_by_email: false)

      event = Event.create!(target: repository,
                            user: mike,
                            action: Action::CREATE_TAG,
                            project: project)

      assert_equal [moe], EmailEventSubscribers::EventMailer.users_to_notify(event)
    end
  end

  context "#notify" do
    should "not notify about commit events" do
      event = Event.new(action: Action::COMMIT)
      user = User.new

      Mailer.expects(:deliver_favorite_notification).never

      EmailEventSubscribers::EventMailer.new(event, [user]).notify
    end

    should "send email with an notification to recipients" do
      event = Event.new(action: Action::COMMENT)
      user = User.new

      EventRendering::Text.stubs(:render).with(event).returns("foo")
      Mailer.expects(:deliver_favorite_notification).with(user, "foo")

      EmailEventSubscribers::EventMailer.new(event, [user]).notify
    end
  end
end
