# encoding: utf-8
#--
#   Copyright (C) 2011-2013 Gitorious AS
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
require "use_cases/create_system_user"

module Gitorious
  module Authentication
    class SSLAuthentication
      attr_reader(:login_field, :login_replace_char, :login_strip_domain)

      def initialize(options)
        @login_field = options['login_field'] || 'CN'
        @login_replace_char = options['login_replace_char'] || '-'
        @login_strip_domain = options['login_strip_domain']
      end

      def authenticate(credentials)
        return false unless credentials.env
        username = username_from_ssl_header(credentials.env)
        User.find_by_login(username) || auto_register(username, credentials.env)
      end

      def username_from_ssl_header(env)
        username = env['SSL_CLIENT_S_DN_' + login_field]
        username = username.split('@')[0] if login_strip_domain
        username.gsub(/[^a-z0-9\-]/i, login_replace_char)
      end

      def auto_register(username, env)
        CreateSystemUser.new.execute({
            :login => username,
            :email => env["SSL_CLIENT_S_DN_Email"],
            :fullname => env["SSL_CLIENT_S_DN_CN"]
          }).result
      end
    end
  end
end
