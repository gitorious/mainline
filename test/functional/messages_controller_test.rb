# encoding: utf-8
#--
#   Copyright (C) 2011-2012 Gitorious AS
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

class MessagesControllerTest < ActionController::TestCase
  should_render_in_global_context

  def setup
    setup_ssl_from_config
  end

  context "On GET to index" do
    setup do
      login_as :moe
    end

    should "request page" do
      get :index

      assert_response :success
      assert_not_nil assigns(:messages)
      assert_template("messages/index")
    end

    should "not display messages from self as new" do
      Message.destroy_all
      moe = users(:moe)
      SendMessage.call(:recipient => moe, :sender => moe, :subject => "Yo", :body => "Mama")

      get :index

      assert_match /No messages/, @response.body
    end

    context "paginating messages" do
      should_scope_pagination_to(:index, Message)
    end
  end

  should "GET sent" do
    login_as :moe
    get :sent

    assert_response :success
    assert_not_nil assigns(:messages)
    assert_template("messages/index")
  end

  context "paginating sent messages" do
    setup do
      login_as :moe
      get :sent
    end

    should_scope_pagination_to(:sent, Message, "sent messages")
  end

  should "GET show" do
    @message = messages(:johans_message_to_moe)
    login_as :moe
    get :show, :id => @message.to_param

    assert_response :success
    assert_not_nil assigns(:message)
  end

  context "On GET to show (marking as read)" do
    setup do
      login_as :moe
      @message = messages(:johans_message_to_moe)
      @message.build_reply({
          :body => "indeed", :sender => users(:moe), :recipient => users(:moe)
        }).save!
      @message.build_reply({
          :body => "quite", :sender => users(:johan), :recipient => users(:moe)
        }).save!
    end

    should "mark all messages as read when viewing a thread" do
      get :show, :id => @message.to_param
      assert_response :success
      messages_in_thread = UserMessages.for(users(:moe)).all_in_thread(@message)
      assert_equal [true]*3, messages_in_thread.map { |m| m.read_by?(users(:moe)) }
    end
  end

  should "not allow peeking at other people's messages" do
    message = messages(:johans_message_to_moe)
    login_as :mike
    get :show, :id => message.to_param

    assert_response :not_found
  end

  should "PUT read" do
    login_as :moe
    message = messages(:johans_message_to_moe)
    put :read, :id => message.to_param, :format => "js"

    assert_response :success
    assert_equal message, assigns(:message)
  end

  should "POST to create" do
    login_as :moe
    post :create, :message => {:subject => "Hello", :body => "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.", :recipient_logins => "johan"}

    assert_response :redirect
    assert_match /sent/i, flash[:notice]
  end

  context "POST to create with several recipients" do
    setup { login_as :moe }

    context "separating user names with tokens" do
      should "support a comma" do
        assert_incremented_by Message, :count, 1 do
          post :create, :message => {
            :subject => "Hello",
            :body => "This is for several recipients",
            :recipient_logins => %w(johan mike).join(",")
          }
        end
      end

      should "support a whitespace character" do
        assert_incremented_by Message, :count, 1 do
          post :create, :message => {
            :subject => "Hello",
            :body => "This is for several recipients",
            :recipient_logins => %w(johan mike).join(" ")
          }
        end
      end

      should "support a period" do
        assert_incremented_by Message, :count, 1 do
          post :create, :message => {
            :subject => "Hello",
            :body => "This is for several recipients",
            :recipient_logins => %w(johan mike).join(".")
          }
        end
      end
    end
  end

  should "POST to reply" do
    login_as :moe
    @original_message = messages(:johans_message_to_moe)
    post :reply, :id => @original_message.to_param, :message => {
      :body => "Yeah, great idea",
      :subject => "Well"
    }

    assert_response :redirect
    assert_match /sent/i, flash[:notice]
    assert_not_nil assigns(:message)
    assert_equal("Well", assigns(:message).subject)
  end

  should "GET new" do
    login_as :johan
    get :new

    assert_response :success
    assert_template "messages/new"

    assert_not_nil assigns(:message)
    assert_equal(users(:johan), assigns(:message).sender)
  end

  should "insert the username on GET new if the to querystring param is given" do
    login_as :johan
    get :new, :to => users(:mike).login
    assert_select "#message_recipient_logins[value=?]", users(:mike).login
  end

  should "GET all" do
    login_as :johan
    get :all

    assert_not_nil assigns(:messages)
    assert_response :success
    assert_template("messages/index")
  end

  context "paginating all" do
    setup do
      login_as :johan
      get :all
    end

    should_scope_pagination_to(:all, Message)
  end

  context "POST to auto_complete_for_message_recipients" do
    setup { login_as :johan }

    should "not include current_user when looking up" do
      post :auto_complete_for_message_recipients, :q => "joh"
      assert_equal("", assigns(:users))
    end

    should "assign an array of users when looking up" do
      post :auto_complete_for_message_recipients, :q => "mik"
      assert_equal("mike", users(:mike).login)
    end
  end

  context "On PUT to bulk_update" do
    setup do
      @sender = FactoryGirl.create(:user)
      @recipient = FactoryGirl.create(:user)
      @messages = 4.times.collect do |i|
        Message.create(:sender => @sender,
                       :recipient => @recipient,
                       :subject => "Message #{i}",
                       :body => "Hello world")
      end
    end

    should "mark the selected messages as read when supplying no action" do
      #@request.session[:user_id] = @recipient.id
      login_as @recipient
      put :bulk_update, :message_ids => @messages.collect(&:id)
      assert_response :redirect

      read = @messages.map{|m| m.reload.read_by?(@recipient)}
      assert_equal [true] * 4, read
    end

    should "archive the selected messages for the current user" do
      @request.session[:user_id] = @recipient.id
      put :bulk_update, :message_ids => @messages.collect(&:id), :requested_action => "archive"
      assert_response :redirect

      @messages.each do |msg|
        assert msg.reload.archived_by?(@recipient)
      end
    end
  end

  context "Sender disappears" do
    setup { @message = messages(:johans_message_to_moe) }

    should "render without error" do
      users(:johan).destroy
      login_as :moe
      get :index

      assert_response :success
    end
  end

  should "disallow unauthenticated GET to index" do
    get :index

    assert_response :redirect
  end

  context "Fishy data" do
    setup do
      @data = "0x|x00|x08|x20|x0B|x0C|x0E-|x1F|x82|x83|x84|x91|x92|x93|x94|u201C|u201D|u201E|u201F|u2033|u2036|u2018|u2019|u201A|u201B|u2032|u2035|\xc2\xad|\xcc\xb7|\xcc\xb8|\xe1\x85\x9F|\xe1\x85\xA0|\xe2\x80\x80|\xe2\x80\x81|\xe2\x80\x82|\xe2\x80\x83|\xe2\x80\x84|\xe2\x80\x85|\xe2\x80\x86|\xe2\x80\x87|\xe2\x80\x88|\xe2\x80\x89|\xe2\x80\x8a|\xe2\x80\x8b|\xe2\x80\x8e|\xe2\x80\x8f|\xe2\x80\xaa|\xe2\x80\xab|\xe2\x80\xac|\xe2\x80\xad|\xe2\x80\xae|\xe2\x80\xaf|\xe2\x81\x9f|\xe3\x80\x80|\xe3\x85\xa4|\xef\xbb\xbf|\xef\xbe\xa0|\xef\xbf\xb9|\xef\xbf\xba|\xef\xbf\xbb|\xE2\x80\x8D"
      login_as :moe
    end

    should "not cause errors" do
      post :create, :message => {:subject => @data, :body => @data, :recipient_logins => "johan"}
      assert_redirected_to :action => :index
    end
  end
end
