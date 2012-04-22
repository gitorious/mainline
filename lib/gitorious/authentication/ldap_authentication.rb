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
        :connection_type, :distinguished_name_template, :connection, :login_attribute)

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
        @login_attribute = options["login_attribute"] || "CN"
        @server = options["host"] || options["server"]
        @port = (options["port"] || 389).to_i
        @attribute_mapping = options["attribute_mapping"] || default_attribute_mapping
        encryption_opt = options["encryption"] || "simple_tls"
        @encryption = encryption_opt.to_sym if encryption_opt != "none"
        @base_dn = options["base_dn"]
        @connection_type = options["connection_type"] || Net::LDAP
        @callback_class = options["callback_class"].constantize if options.key?("callback_class")
        build_distinguished_name_template(options["distinguished_name_template"])
      end

      def post_authenticate(options)
        if @callback_class
          return @callback_class.post_authenticate(options)
        else
          return true
        end
      end

      # Ask the LDAP server if the credentials are correct
      def valid_credentials?(username, password)
        return false if password.blank?

        @connection  = @connection_type.new({:encryption => encryption, :host => server, :port => port})
        connection.auth(build_username(username), password)
        return connection.bind
      end

      # The actual authentication callback
      def authenticate(credentials)
        return false unless valid_credentials?(credentials.username, credentials.password)
        if existing_user = User.find_by_login(transform_username(credentials.username))
          user = existing_user
        else
          user = auto_register(credentials.username)
        end

        return unless post_authenticate({
            :connection => connection,
            :username => credentials.username,
            :user_filter => username_filter(credentials.username),
            :base_dn => base_dn})
        user
      end

      # Transform a username usable towards LDAP into something that passes Gitorious'
      # username validations
      def transform_username(username)
        username.gsub(".", "-")
      end

      def auto_register(username)
        result = connection.search(:base => base_dn, :filter => username_filter(username),
          :attributes => attribute_mapping.keys, :return_result => true)
        if result.size > 0
          data = result.first
          user = User.new
          user.login = transform_username(username)
          attribute_mapping.each do |ldap_name, our_name|
            user.write_attribute(our_name, data[ldap_name].first)
          end

          user.password = "left_blank"
          user.password_confirmation = "left_blank"
          user.terms_of_use = '1'
          user.aasm_state = "terms_accepted"
          user.activated_at = Time.now.utc
          user.save!
          user
        end
      end

      private

      def username_filter(username)
        Net::LDAP::Filter.eq(login_attribute, username)
      end

      # The default mapping of LDAP -> User attributes
      def default_attribute_mapping
        {"displayname" => "fullname", "mail" => "email"}
      end

      def build_username(login)
        distinguished_name_template.sub("{}", login)
      end

      def build_distinguished_name_template(template)
        @distinguished_name_template = template || "#{login_attribute}={},#{base_dn}"
      end

    end
  end
end
