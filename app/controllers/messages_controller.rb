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
      current_user.messages_in_inbox.paginate(:page => params[:page])
    }

    render_index
  end

  def all
    @messages = paginate(page_free_redirect_options) {
      current_user.top_level_messages.paginate(:page => params[:page])
    }

    render_index
  end

  def sent
    @messages = paginate(page_free_redirect_options) {
      current_user.sent_messages.paginate(:page => params[:page])
    }

    render_index
  end

  def read
    @message = current_user.received_messages.find(params[:id])
    @message.read

    respond_to do |wants|
      wants.js { head :ok }
    end
  end

  def bulk_update
    message_ids = params[:message_ids].to_a
    message_ids.each do |message_id|
      message = Message.involving_user(current_user).find(message_id)
      if params[:requested_action] == 'archive'
        message.archived_by(current_user)
        message.save!
      else
        logger.info("Marking message #{message_id} as read")
        message.read
      end
    end
    redirect_to :action => :index
  end

  def show
    @message = Message.find(params[:id])

    if !can_read?(current_user, @message)
      raise ActiveRecord::RecordNotFound and return
    end

    @message.mark_thread_as_read_by_user(current_user)

    respond_to do |wants|
      wants.html { render :show }
      wants.xml  { render :xml => @message }
      wants.js   { render :partial => "message", :layout => false }
    end
  end

  def create
    thread_options = params[:message].merge(
      :recipients => params[:message][:recipient_logins],
      :sender => current_user
    )

    @messages = MessageThread.new(thread_options)
    @messages.save!
    flash[:notice] = "#{@messages.title} sent"
    redirect_to :action => :index
  rescue SendMessage::InvalidMessage
    @message = @messages.validated_message
    render :new
  end

  def new
    @message = Message.new(:sender => current_user, :recipient_logins => params[:to])
  end

  # POST /messages/<id>/reply
  def reply
    original_message = current_user.received_messages.find(params[:id])
    @message = SendReply.call(original_message, params[:message])
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

    respond_to do |wants|
      wants.html { render "messages/index" }
      wants.xml  { render :xml => @messages }
    end
  end
end
