# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
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
require "net/ldap"
module Gitorious
  module Authentication
    class LDAPAuthentication
      attr_reader :server, :port, :encryption, :attribute_mapping, :base_dn, :connection
      
      def initialize(options)
        validate_requirements(options)
        setup_attributes(options)
      end

      def validate_requirements(options)
        raise ConfigurationError, "Server name required" unless options.key?("server")
        raise ConfigurationError, "Base DN required" unless options.key?("base_dn")
      end
        
      def setup_attributes(options)
        @server = options["server"]
        @port = (options["port"] || 389).to_i
        @attribute_mapping = options["attribute_mapping"] || default_attribute_mapping
        @encryption = (options["encryption"] || "simple_tls").to_sym
        @base_dn = options["base_dn"]
        @connection = options["connection"] || Net::LDAP.new
      end

      # The actual authentication callback
      def authenticate(username, password)
      end

      # The default mapping of LDAP -> User attributes
      def default_attribute_mapping
        {"displayname" => "fullname", "mail" => "email"}
      end
    end
  end
end
