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

require "will_paginate/array"

class MessagesController < ApplicationController
  before_filter :login_required

  renders_in_global_context

  def index
    @messages = paginate(page_free_redirect_options) {
      user_messages.inbox.paginate(:page => params[:page])
    }

    render_index
  end

  def all
    @messages = paginate(page_free_redirect_options) {
      user_messages.all.paginate(:page => params[:page])
    }

    render_index
  end

  def sent
    @messages = paginate(page_free_redirect_options) {
      user_messages.sent.paginate(:page => params[:page])
    }

    render_index
  end

  def read
    @message = user_messages.find(params[:id])
    @message.mark_as_read_by_user(current_user)

    respond_to do |wants|
      wants.js { head :ok }
    end
  end

  def bulk_update
    message_ids = params[:message_ids].to_a
    message_ids.each do |message_id|
      message = user_messages.find(message_id)
      if params[:requested_action] == 'archive'
        message.mark_as_archived_by_user(current_user)
        message.save!
      else
        logger.info("Marking message #{message_id} as read")
        message.mark_as_read_by_user(current_user)
      end
    end
    redirect_to :action => redirect_action(params[:return_to_action])
  end

  def show
    @message = user_messages.find(params[:id])
    @reply = @message.build_reply(sender: current_user)

    @message.mark_thread_as_read_by_user(current_user)

    respond_to do |wants|
      wants.html { render :show }
      wants.js   { render :partial => "message", :layout => false }
    end
  end

  def create
    message_params = params[:message] || {}

    SendMessage.call(
      sender: current_user,
      recipient_logins: message_params[:recipient_logins],
      subject: message_params[:subject],
      body: message_params[:body]
    )

    flash[:notice] = "Message sent"
    redirect_to :action => :index
  rescue SendMessage::InvalidMessage => invalid
    @message = invalid.record
    render :new
  end

  def new
    @message = Message.new(:sender => current_user, :recipient_logins => params[:to])
  end

  # POST /messages/<id>/reply
  def reply
    original_message = user_messages.find(params[:id])
    message_params = params[:message].merge(sender: current_user)
    @message = SendReply.call(original_message, message_params)
    flash[:notice] = "Your reply was sent"
    redirect_to :action => :show, :id => original_message
  rescue SendMessage::InvalidMessage
    flash[:error] = "Your message could not be sent"
    redirect_to :action => :index
  end

  def auto_complete_for_message_recipients
    @users = User.find_fuzzy(params[:q]).reject{|u|u == current_user}.map{|u| u.login }.join("\n")
    render :text => @users, :content_type => Mime::TEXT
  end

  private

  def render_index
    return if @messages.count == 0 && params.key?(:page)

    render "messages/index"
  end

  def user_messages
    @user_messages ||= UserMessages.for(current_user)
  end

  def redirect_action(action_name)
    ['index', 'all', 'sent'].include?(action_name) ? action_name : 'index'
  end
end
