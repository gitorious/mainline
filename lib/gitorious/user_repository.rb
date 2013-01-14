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
require "gitorious/authorization"

module Gitorious
  class UserRepository
    include Gitorious::Authorization

    def initialize(user, repository, url_generator)
      @user = user
      @repository = repository
      @url_generator = url_generator
    end

    def to_json
      return "{}" if @user.nil?
      JSON.dump({
        "user" => user_hash,
        "repository" => repository_hash
      })
    end

    private
    def user_hash
      {
        "login" => @user.login,
        "unreadMessageCount" => @user.unread_message_count,
        "dashboardPath" => @url_generator.root_path,
        "profilePath" => @url_generator.user_path(@user),
        "editPath" => @url_generator.edit_user_path(@user),
        "messagesPath" => @url_generator.messages_path
      }
    end

    def repository_hash
      return "{}" if @repository.nil?
      {
        "administrator" => !!admin?(@user, @repository),
        "watching" => @user.watching?(@repository),
        "cloneProtocols" => clone_protocols
      }
    end

    def clone_protocols
      [].tap do |protocols|
        protocols << "git" if @repository.git_cloning?
        protocols << "http" if @repository.http_cloning?
        protocols << "ssh" if @repository.display_ssh_url?(@user)
      end
    end
  end
end
