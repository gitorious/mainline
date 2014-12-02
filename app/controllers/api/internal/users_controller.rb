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

    class UsersController < BaseController
      respond_to :json

      def authenticate
        user = authenticate_user(params[:username], params[:password])

        if user
          respond_with({ username: user.login })
        else
          head :unauthorized
        end
      end

      private

      def authenticate_user(username, password)
        credentials = Gitorious::Authentication::Credentials.new
        credentials.username = username
        credentials.password = password

        Gitorious::Authentication.authenticate(credentials)
      end
    end

  end
end
