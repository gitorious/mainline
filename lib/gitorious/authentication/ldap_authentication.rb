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
      attr_reader(:server, :port, :encryption, :attribute_mapping, :base_dn,
        :connection_type, :distinguished_name_template, :connection,
        :bind_username, :bind_password, :username_attribute)


      def initialize(options)
        validate_requirements(options)
        setup_attributes(options)
      end

      def validate_requirements(options)
        server_provided = options.key?("server") || options.key?("host")
        raise ConfigurationError, "Server name required" unless server_provided
        raise ConfigurationError, "Base DN required" unless options.key?("base_dn")
      end

      def setup_attributes(options)
        @server = options["host"] || options["server"]
        @port = (options["port"] || 389).to_i
        @attribute_mapping = options["attribute_mapping"] || default_attribute_mapping
        encryption_opt = options["encryption"] || "simple_tls"
        @encryption = encryption_opt.to_sym if encryption_opt != "none"
        @base_dn = options["base_dn"]
        @connection_type = options["connection_type"] || Net::LDAP
        @callback_class = options["callback_class"].constantize if options.key?("callback_class")
        build_distinguished_name_template(options["distinguished_name_template"])
        @bind_username = options["bind_username"]
        @bind_password = options["bind_password"]
        @username_attribute = options["username_attribute"] || "cn"
      end

      def post_authenticate(options)
        if @callback_class
          return @callback_class.post_authenticate(options)
        else
          return true
        end
      end

      # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
      def valid_credentials?(username, password)
        if @bind_username.nil?
            return ldap_valid_credentials?(build_username(username), password)
        else
            dn = get_dn_of_user(username)
            return false unless dn
            return ldap_valid_credentials?(dn, password)
        end
        return false
      end

      # The actual authentication callback
      def authenticate(username, password)
        return false unless valid_credentials?(username, password)
        if existing_user = User.find_by_login(transform_username(username))
          user = existing_user
        else
          user = auto_register(username)
        end

        return unless post_authenticate({:connection => connection, :username => username})
        user
      end

      # Transform a username usable towards LDAP into something that passes Gitorious'
      # username validations
      def transform_username(username)
        username.gsub(".", "-")
      end

      def auto_register(username)
        filter = Net::LDAP::Filter.eq(@username_attribute, username)
        result = connection.search(:base => base_dn, :filter => filter,
          :attributes => attribute_mapping.keys, :return_result => true, :size => 1)
        if result.size > 0
          data = result.first
          user = User.new
          user.login = transform_username(username)
          attribute_mapping.each do |ldap_name, our_name|
            user.write_attribute(our_name, [*data[ldap_name]].first)
          end

          user.password = "left_blank"
          user.password_confirmation = "left_blank"
          user.terms_of_use = '1'
          user.aasm_state = "terms_accepted"
          user.activated_at = Time.now.utc
          user.save
          return user
        end
        nil
      end

      def build_username(login)
        distinguished_name_template.sub("{}", login)
      end

      # return the dn of the user that has an attribute named search_attribute with a value of seach_value, or nil if not found
      def get_dn_of_user(search_value)
        if @bind_username
          connect
          connection.auth(@bind_username, @bind_password)
          if connection.bind
            filter = Net::LDAP::Filter.eq("objectClass", "user") & Net::LDAP::Filter.eq(@username_attribute, search_value)
            result = connection.search(:base => @base_dn, :filter => filter,
              :attributes => [], :return_result => true, :size => 1)
            if result.size > 0
              return [*result.first["dn"]].first
            end
          end
        end
        nil
      end

      private

      # The default mapping of LDAP -> User attributes
      def default_attribute_mapping
        {"displayname" => "fullname", "mail" => "email"}
      end

      # Ask the LDAP server if the credentials are correct
      def ldap_valid_credentials?(username, password)
        return false if password.blank?
        connect
        connection.auth(username, password)
        return connection.bind
      end

      def connect
        @connection ||= @connection_type.new({:encryption => encryption, :host => server, :port => port})
      end

      def build_distinguished_name_template(template)
        @distinguished_name_template = template || "CN={},#{base_dn}"
      end

    end
  end
end
