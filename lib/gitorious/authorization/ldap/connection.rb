 # encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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
  module Authorization
    module LDAP
      class Connection
        attr_reader :options
        
        def initialize(options)
          @options = options
        end

        def bind_as(bind_user_dn, bind_user_pass)
          connection = Net::LDAP.new({:host => options[:host], :port => options[:port], :encryption => options[:encryption]})
          connection.auth(bind_user_dn, bind_user_pass)
          begin
            if connection.bind
              yield BoundConnection.new(connection)
            end
          rescue Net::LDAP::LdapError => e
            raise LdapError, "Unable to connect to the LDAP server on #{options[:host]}:#{options[:port]}. Are you sure the LDAP server is running?"
          end
        end

        class BoundConnection
          def initialize(native_connection)
            @native_connection = native_connection
          end

          def search(options)
            @native_connection.search(options)
          end
        end

        class LdapError < StandardError;end
      end
    end
  end
end
