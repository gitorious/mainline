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
  module Authentication
    class LDAPConfigurator
      attr_reader :options
      
      def initialize(options_hash)
        @options = options_hash
      end

      def login_attribute
        options["login_attribute"] || "CN"
      end

      def server
        options["host"] || options["server"]
      end

      def port
        (options["port"] || 389).to_i
      end

      def attribute_mapping
        options["attribute_mapping"] || default_attribute_mapping
      end

      def encryption
        encryption_opt = options["encryption"] || "simple_tls"
        encryption_opt.to_sym if encryption_opt != "none"
      end

      def base_dn
        options["base_dn"]
      end

      def group_search_dn
        options.fetch("group_search_dn", base_dn)
      end
      
      def connection_type
        @connection_type = options["connection_type"] || Net::LDAP
      end

      def authentication_callback_class
        options["callback_class"].constantize if options.key?("callback_class")
      end

      def distinguished_name_template
        options["distinguished_name_template"] || "#{login_attribute}={},#{base_dn}"
      end
      
      # The default mapping of LDAP -> User attributes
      def default_attribute_mapping
        {"displayname" => "fullname", "mail" => "email"}
      end

      def bind_username
        options["bind_user"] && options["bind_user"]["username"]
      end

      def bind_password
        options["bind_user"] && options["bind_user"]["password"]
      end

      # The name of the membership attribute name (9/10 times this is the default)
      def membership_attribute_name
        options.fetch("membership_attribute_name", "memberof").to_sym
      end
      
      # The name of the members attribute name. Depending on the LDAP schema
      def members_attribute_name
        options.fetch("members_attribute_name", "member").to_sym
      end

      def cache_expiry
        options.fetch("cache_expiry",nil).to_i
      end

      def self.transform_username(username)
        username.gsub(".","-")
      end

      def reverse_username_transformation(username)
        username.gsub("-",".")
      end
    end
  end
end
