# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2009 Fabio Akita <fabio.akita@gmail.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
#   Copyright (C) 2007 Johan Sørensen <johan@johansorensen.com>
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

class KeysController < ApplicationController
  include Gitorious::Messaging::Publisher
  before_filter :login_required
  before_filter :find_user
  before_filter :require_current_user
  renders_in_global_context

  def index
    @ssh_keys = current_user.ssh_keys
    @root = Breadcrumb::Keys.new(current_user)
    respond_to do |format|
      format.html
      format.xml { render :xml => @ssh_keys }
    end
  end

  def new
    @ssh_key = current_user.ssh_keys.new
    @root = Breadcrumb::NewKey.new(current_user)
  end

  def create
    outcome = CreateSshKey.new(self, current_user).execute(params[:ssh_key])

    respond_to do |format|
      outcome.success do |result|
        flash[:notice] = I18n.t("keys_controller.create_notice")
        format.html { redirect_to(user_keys_path(current_user)) }
        format.xml do
          key_path = user_key_path(current_user, result)
          render(:xml => result, :status => :created, :location => key_path)
        end
      end

      outcome.failure do |key|
        format.html do
          @ssh_key = key
          @root = Breadcrumb::NewKey.new(current_user)
          render :action => "new"
        end
        format.xml do
          render(:xml => key.errors.full_messages, :status => :unprocessable_entity)
        end
      end
    end
  end

  def show
    @ssh_key = current_user.ssh_keys.find(params[:id])

    respond_to do |format|
      format.html
      format.xml { render :xml => @ssh_key }
    end
  end

  def destroy
    outcome = DestroySshKey.new(self, current_user).execute(params)

    outcome.success do
      flash[:notice] = I18n.t("keys_controller.destroy_notice")
      redirect_to(user_keys_path(current_user)) and return
    end

    render(:text => "Bad request", :status => 400)
  end

  protected
  def find_user
    @user = User.find_by_login!(params[:user_id])
  end
end
