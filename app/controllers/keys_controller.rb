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
    respond_to do |format|
      format.xml { render(:xml => current_user.ssh_keys) }
      format.html { redirect_to(user_edit_ssh_keys_path(current_user)) }
    end
  end

  def new
    render_form
  end

  def create
    outcome = CreateSshKey.new(self, current_user).execute(params[:ssh_key])

    respond_to do |format|
      outcome.success do |result|
        flash[:notice] = I18n.t("keys_controller.create_notice")

        format.html do
          redirect_to user_edit_ssh_keys_path(current_user)
        end

        format.xml do
          key_path = user_key_path(current_user, result)
          render(:xml => result, :status => :created, :location => key_path)
        end
      end

      outcome.failure do |ssh_key|
        format.html do
          @ssh_key = ssh_key
          render_form
        end

        format.xml do
          render(:xml => ssh_key.errors.full_messages, :status => :unprocessable_entity)
        end
      end
    end
  end

  def destroy
    outcome = DestroySshKey.new(self, current_user).execute(params)

    outcome.success do
      flash[:notice] = I18n.t("keys_controller.destroy_notice")
      redirect_to user_edit_ssh_keys_path(current_user) and return
    end
  end

  protected

  def find_user
    @user = User.find_by_login!(params[:user_id])
  end

  def render_form(ssh_key = @ssh_key)
    render("users/edit", :locals => {
      :user => current_user, :active_tab => "ssh-keys", :ssh_key => ssh_key
    })
  end

end
