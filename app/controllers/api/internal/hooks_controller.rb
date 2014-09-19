# encoding: utf-8
#--
#   Copyright (C) 2014 Gitorious AS
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

module Api
  module Internal

    class HooksController < ApplicationController
      include Gitorious::Messaging::Publisher

      # params: username, repo_path, refname, oldsha, newsha, mergebase
      def pre_receive
        user = User.find_by_login(params[:username])
        repository = Repository.find_by_path(params[:repo_path])

        RefPolicy.authorize_action!(user, repository, params[:refname], params[:oldsha], params[:newsha], params[:mergebase])
        head :ok

      rescue RefPolicy::Error => e
        render text: e.message, status: :forbidden
      end

      # params: username, repo_path, refname, oldsha, newsha
      def post_receive
        publish("/queue/GitoriousPush", {
          gitdir:   params[:repo_path].sub(/\.git$/, ""),
          message:  "#{params[:oldsha]} #{params[:newsha]} #{params[:refname]}",
          username: params[:username],
        })

        head :ok
      end
    end

  end
end
