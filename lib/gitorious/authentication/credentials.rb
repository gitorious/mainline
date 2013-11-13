#--
#   Copyright (C) 2012-2013 Gitorious AS
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

# Pass an instance of this class to a Gitorious::Authentication plugin's
# authenticate method.
module Gitorious
  module Authentication
    class Credentials
      attr_accessor :username, :password, :env
      # "username" is the client-supplied username value.
      # "password" is the client-supplied password value.
      # "env" is the HTTP environment from the web server.
      # If you use "env", you may want to examine env['REMOTE_USER'],
      # etc.
    end
  end
end
