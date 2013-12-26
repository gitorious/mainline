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

class UserJSONPresenter
  def initialize(app, user)
    @app = app
    @user = user
  end

  def render
    JSON.dump(to_hash)
  end

  def unread_message_count
    UserMessages.for(user).unread_count
  end

  def to_hash
    return {} if user.nil?
    { "user" => {
        "login" => user.login,
        "unreadMessageCount" => unread_message_count,
        "dashboardPath" => app.root_path,
        "profilePath" => app.user_path(user),
        "editPath" => app.edit_user_path(user),
        "messagesPath" => app.messages_path,
        "logoutPath" => app.logout_path,
        "avatarUrl" => app.avatar_url(user)
      } }
  end

  private
  attr_reader :app, :user
end
