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

module Gitorious
  module ViewState
    class UserRepository
      def initialize(app, repository, user)
        @app = app
        @repository = repository
        @user = user
      end

      def to_json
        return "{}" if user.nil?
        JSON.dump({
          "user" => user_hash,
          "repository" => repository_hash
        })
      end

      private
      def user_hash
        {
          "login" => user.login,
          "unreadMessageCount" => user.unread_message_count,
          "dashboardPath" => app.root_path,
          "profilePath" => app.user_path(user),
          "editPath" => app.edit_user_path(user),
          "messagesPath" => app.messages_path,
          "logoutPath" => app.logout_path,
          "avatarPath" => app.avatar_url(user)
        }
      end

      def repository_hash
        return nil if repository.nil?
        is_admin = !!app.admin?(user, repository)
        {
          "administrator" => is_admin,
          "watch" => watch,
          "cloneProtocols" => clone_protocols,
          "clonePath" => clone_path,
          "requestMergePath" => request_merge_path
        }.merge(is_admin ? repo_admin_hash : {})
      end

      def clone_protocols
        { "protocols" => [] }.tap do |cp|
          cp["protocols"] << "git" if repository.git_cloning?
          cp["protocols"] << "http" if repository.http_cloning?

          if repository.display_ssh_url?(user)
            cp["protocols"] << "ssh"
            cp["default"] = "ssh"
          else
            cp["default"] = repository.default_clone_protocol
          end
        end
      end

      def repo_admin_hash
        { "admin" => {
            "editPath" => app.edit_project_repository_path(project, repository),
            "destroyPath" => app.confirm_delete_project_repository_path(project, repository),
            "ownershipPath" => app.transfer_ownership_project_repository_path(project, repository),
            "committershipsPath" => app.project_repository_committerships_path(project, repository)
          }
        }
      end

      def watch
        favorite = user.favorites.find { |f| f.watchable == repository }
        hash = {
          "watching" => !favorite.nil?,
          "watchPath" => app.favorites_path(:watchable_id => repository.id,
                                            :watchable_type => "Repository")
        }
        hash["unwatchPath"] = app.favorite_path(favorite) if !favorite.nil?
        hash
      end

      def clone_path
        return nil if repository.parent && repository.owner == user
        app.clone_project_repository_path(repository.project, repository)
      end

      def request_merge_path
        return nil if user.nil? || repository.parent.nil? || !app.admin?(user, repository)
        app.new_project_repository_merge_request_path(repository.project, repository.parent)
      end

      def app; @app; end
      def repository; @repository; end
      def project; @repository.project; end
      def user; @user; end
    end
  end
end
