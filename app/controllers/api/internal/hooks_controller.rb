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

    class HooksController < BaseController
      include Gitorious::Messaging::Publisher

      # params: username, repository_id, refname, oldsha, newsha, mergebase
      def pre_receive
        user = User.find_by_login(params[:username])
        repository = Repository.find(params[:repository_id])

        RefPolicy.authorize_action!(user, repository, params[:refname], params[:oldsha], params[:newsha], params[:mergebase])
        head :ok

      rescue RefPolicy::Error => e
        render text: e.message, status: :forbidden
      end

      # params: username, repository_id, refname, oldsha, newsha
      def post_receive
        publish("/queue/GitoriousPush", {
          repository_id: params[:repository_id],
          message:  "#{params[:oldsha]} #{params[:newsha]} #{params[:refname]}",
          username: params[:username],
          pushed_at: Time.now.iso8601,
        })

        head :ok
      end

      private

      def clock
        Time
      end
    end

  end
end
