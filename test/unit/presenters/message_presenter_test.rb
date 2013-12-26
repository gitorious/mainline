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

require 'test_helper'

class MessagePresenterTest < MiniTest::Spec
  include ViewContextHelper

  let(:presenter) { MessagePresenter.new(msg, viewer, nil) }
  let(:viewer) { User.new }
  let(:msg) { Message.new }
  let(:user_messages) { stub }

  before do
    UserMessages.stubs(:for).with(viewer).returns(user_messages)
  end

  it "delagtes to message" do
    methods = :id, :to_key, :body, :created_at, :subject, :notifiable, :to_param
    methods.each do |method|
      msg.stubs(method).returns(:delegated)

      assert_equal :delegated, presenter.send(method)
    end
  end

  it "defines the model name" do
    assert_equal Message.model_name, MessagePresenter.model_name
  end

  describe "#message_class" do
    it "returns unread for unread messages" do
      msg.stubs(:read_by?).with(viewer).returns(false)

      assert_equal "unread message message full", presenter.message_class
    end

    it "returns read for read messages" do
      msg.stubs(:read_by?).with(viewer).returns(true)

      assert_equal "read message message full", presenter.message_class
    end
  end

  describe "messages in thread" do
    let(:another_msg) { Message.new }
    before do
      user_messages.stubs(all_in_thread: [msg, another_msg])
    end

    it "returns decorated messages in thread" do
      expected_presenters = [presenter, MessagePresenter.new(another_msg, viewer, nil)]
      assert_equal expected_presenters, presenter.messages_in_thread
    end

    it "counts the number of messages in thread" do
      assert_equal 2, presenter.number_of_messages_in_thread
    end
  end

  describe "#thread_class" do
    it "returns css classes for read threads" do
      user_messages.stubs(:thread_unread?).with(msg).returns(true)

      assert_equal "unread message", presenter.thread_class
    end

    it "returns css classes for unread threads" do
      user_messages.stubs(:thread_unread?).with(msg).returns(false)

      assert_equal "read message", presenter.thread_class
    end
  end

  it "formats the sender and recpients" do
    presenter.view_context = view_context
    msg.sender = viewer
    msg.recipients = [stub_user("joe")]

    expected = %Q{me and <a href="/~joe">joe</a>}
    assert_equal expected, presenter.sender_and_recipients
  end

  describe "#unread_by_viewer?" do
    it "returns true for messages unread messages of viewer" do
      msg.stubs(:read_by?).with(viewer).returns(false)
      msg.recipients = [viewer]

      assert presenter.unread_by_viewer?
    end

    it "returns false for read messages" do
      msg.stubs(:read_by?).with(viewer).returns(true)
      msg.recipients = [viewer]

      refute presenter.unread_by_viewer?
    end

    it "returns false for messages of other users" do
      msg.stubs(:read_by?).with(viewer).returns(true)
      msg.sender = viewer
      msg.recipients = [stub_user("joe")]

      refute presenter.unread_by_viewer?
    end
  end

  describe "#repliable?" do
    it "returns true for messages that were not send by the viewer and with replies enabled" do
      msg.stubs(replies_enabled?: true)
      msg.sender = stub_user("joe")

      assert presenter.repliable?
    end

    it "returns false for messages send by the viewer" do
      msg.stubs(replies_enabled?: true)
      msg.sender = viewer

      refute presenter.repliable?
    end

    it "returns false for messages with replies disabled" do
      msg.sender = stub_user("joe")
      msg.stubs(replies_enabled?: false)

      refute presenter.repliable?
    end
  end

  describe "#message_title" do
    before { presenter.view_context = stub(link_to: 'gitorious/foo') }

    it "formats title for merge requests" do
      msg.notifiable = MergeRequest.new(target_repository: Repository.new)

      assert_includes presenter.message_title, 'about a'
    end

    it "formats title for memberships" do
      msg.notifiable = Membership.new(group: Group.new)

      assert_includes presenter.message_title, 'to the team'
    end

    it "formats title for committerships" do
      msg.notifiable = Committership.new(committer: viewer, repository: Repository.new)

      assert_includes presenter.message_title, 'as committer in'
    end

    it "returns default title otherwise" do
      msg.sender = viewer

      assert_includes presenter.message_title, "from"
    end
  end

  describe "#thread_title" do
    it "returns message subject" do
      msg.subject = "foo"

      assert_equal "foo", presenter.thread_title
    end

    it "returns deafult translation for new messages" do
      assert_equal "Compose a message", presenter.thread_title
    end
  end

  describe "#sender_avatar" do
    before { presenter.view_context = view_context }

    it "returns real avatar with replies enabled" do
      msg.stubs(replies_enabled?: true)
      msg.sender = viewer
      viewer.email = "foo@bar.com"

      assert_includes presenter.sender_avatar, "gravatar.com/avatar"
    end

    it "returns deafault face with replies disabled" do
      msg.stubs(replies_enabled?: false)

      assert_includes presenter.sender_avatar, "default_face.gif"
    end
  end

  def stub_user(name)
    user = User.new(login: name)
    user.stubs(:persisted?).returns(true)
    user
  end
end
