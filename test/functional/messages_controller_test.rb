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

class MessagesControllerTest < ActionController::TestCase
  
  def setup
    @request.env["HTTPS"] = "on"
  end
  
  without_ssl_context do
    context "SSL" do
      setup do
        login_as :moe
      end
      
      context "GET :index" do
        setup { get :index }
        should_redirect_to_ssl
      end
      context "GET :sent" do
        setup { get :sent }
        should_redirect_to_ssl
      end
      context "GET :read" do
        setup { get :read }
        should_redirect_to_ssl
      end
      context "GET :show" do
        setup { get :show }
        should_redirect_to_ssl
      end
      context "POST :create" do
        setup { post :create }
        should_redirect_to_ssl
      end
      context "POST :reply" do
        setup { get :reply }
        should_redirect_to_ssl
      end
      context "POST auto_complete_for_message_recipients" do
        setup { post :auto_complete_for_message_recipients }
        should_redirect_to_ssl
      end
    end
  end
  
  should_render_in_global_context
  
  context 'On GET to index' do
    setup do
      login_as :moe
      get :index
    end
    
    should_respond_with :success
    should_assign_to :messages
    should_render_template :index
  end
  
  context 'On GET to index with XML' do
    setup do
      login_as :moe
      get :index, :format => 'xml'
    end
    should_respond_with :success
    should_assign_to :messages
  end
  
  context 'On GET to sent' do
    setup do
      login_as :moe
      get :sent
    end
    
    should_respond_with :success
    should_assign_to :messages
    should_render_template :sent
  end
  
  context 'On GET to show' do
    setup do 
      @message = messages(:johans_message_to_moe)
      login_as :moe
      get :show, :id => @message.to_param
    end
    
    should_respond_with :success
    should_assign_to :message
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
      assert @message.messages_in_thread.size >= 2, "msg thread only have one msg"
    end

    should "mark all messages as read when viewing a thread" do
      get :show, :id => @message.to_param
      assert_response :success
      assert_equal [true]*3, @message.reload.messages_in_thread.map(&:read?)
    end
  end
  
  context 'On GET to show in XML' do
    setup do 
      @message = messages(:johans_message_to_moe)
      login_as :moe
      get :show, :id => @message.to_param, :format => 'xml'
    end
    
    should_respond_with :success
    should_assign_to :message
  end

  context 'Trying to peek at other peoples messages' do
    setup do
      login_as :mike
      get :show, :id => @message.to_param
    end
    
    should_respond_with :not_found
  end
  
  context 'On PUT to read' do
    setup do
      login_as :moe
      @message = messages(:johans_message_to_moe)
      put :read, :id => @message.to_param, :format => 'js'
    end
    
    should_respond_with :success
    should_assign_to :message#, @message)
  end
  
  context 'On POST to create' do
    setup do
      login_as :moe 
      post :create, :message => {:subject => "Hello", :body => "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.", :recipients => 'johan'}
    end
    
    should_respond_with :redirect
    should_assign_to :messages
    should_set_the_flash_to(/sent/i)
  end
  
  context 'On POST to create with several recipients' do
    setup {login_as :moe}
    
    should 'allow separating recipients with various separating tokens' do
      [',',' ','.'].each do |token|
        assert_incremented_by Message, :count, 2 do
          post :create, :message => {:subject => 'Hello', :body => 'This is for several recipients', :recipients => %w(johan mike).join(token)}
        end
      end
    end

  end
  
  
  context 'On POST to reply' do # POST /messages/2/reply
    setup do
      login_as :moe
      @original_message = messages(:johans_message_to_moe)
      post :reply, :id => @original_message.to_param, :message => {:body => "Yeah, great idea", :subject => "Well"}
    end
    
    should_assign_to :message
    should_respond_with :redirect
    should_set_the_flash_to(/sent/i)
    
    should 'set the correct subject' do
      result = assigns(:message)
      assert_equal("Well", result.subject)
    end
  end
  
  context 'On GET to new' do
    setup do
      login_as :johan
      get :new
    end
    
    should_assign_to :message
    should_respond_with :success
    should_render_template :new
    
    should "set the sender" do
      assert_equal users(:johan), assigns(:message).sender
    end
  end
  
  should "insert the username on GET new if the to querystring param is given" do
    login_as :johan
    get :new, :to => users(:mike).login
    assert_select "#message_recipients[value=?]", users(:mike).login
  end
  
  context 'On GET to all' do
    setup {
      login_as :johan
      get :all
    }
    should_assign_to :messages 
    should_respond_with :success
    should_render_template :all
  end
  context 'On POST to auto_complete_for_message_recipients' do
    setup do
      login_as :johan
    end

    should 'not include current_user when looking up' do
      post :auto_complete_for_message_recipients, :q => "joh", :format => "js"
      assert_equal([], assigns(:users))
    end
    
    should 'assign an array of users when looking up' do
      post :auto_complete_for_message_recipients, :q => "mik", :format => "js"
      assert_equal([users(:mike)], assigns(:users))
    end
  end
  
  context 'On PUT to bulk_update' do
    setup do
      @sender = Factory.create(:user)
      @recipient = Factory.create(:user)
      @messages = (1..10).collect do |i|
        Message.create(:sender => @sender, :recipient => @recipient, :subject => "Message #{i}", :body => "Hello world")
      end
    end
    
    should 'mark the selected messages as read when supplying no action' do
      @request.session[:user_id] = @recipient.id
      put :bulk_update, :message_ids => @messages.collect(&:id)
      assert_response :redirect
      @messages.each do |msg|
        assert msg.reload.read?
      end
    end
    
    should 'archive the selected messages for the current user' do
      @request.session[:user_id] = @recipient.id
      put :bulk_update, :message_ids => @messages.collect(&:id), :requested_action => 'archive'
      assert_response :redirect
      @messages.each do |msg|
        assert msg.reload.archived_by_recipient?
      end
    end
  end
  
  context 'Unauthenticated GET to index' do
    setup {get :index}
    
    should_respond_with :redirect
  end
end
