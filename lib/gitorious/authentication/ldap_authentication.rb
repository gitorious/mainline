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
                  :connection_type, :distinguished_name_template, :connection, :login_attribute, 
                  :bind_user, :bind_password)

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
        configurator = LDAPConfigurator.new(options)
        @login_attribute               = configurator.login_attribute
        @server                        = configurator.server
        @port                          = configurator.port
        @attribute_mapping             = configurator.attribute_mapping
        @encryption                    = configurator.encryption
        @base_dn                       = configurator.base_dn        
        @connection_type               = configurator.connection_type        
        @callback_class                = configurator.authentication_callback_class
        @distinguished_name_template   = configurator.distinguished_name_template
        @bind_user                     = configurator.bind_username
        @bind_password                 = configurator.bind_password
      end

      def use_authenticated_bind?
        !bind_user.blank?
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
        if use_authenticated_bind?
          return authenticated_credentials_check(username, password)
        else
          return anonymous_credentials_check(username, password)
        end
      end

      # If no bind user has been specified, bind directly
      def anonymous_credentials_check(username, password)
        connection.auth(build_username(username), password)
        return connection.bind
      end

      # If a bind user has been supplied:
      # - first bind as the unprivileged bind user
      # - then do a search for a user with the specified credentials, 
      #   and attempt to bind as this user
      # http://net-ldap.rubyforge.org/Net/LDAP.html#method-i-bind_as
      def authenticated_credentials_check(username, password)
        connection.auth(bind_user, bind_password)
        result = connection.bind_as(:base => base_dn,
                                    :filter => username_filter(username),
                                    :password => password)
        if result
          return true
        end
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
        LDAPConfigurator.transform_username(username)
      end

      def auto_register(username)
        result = connection.search(:base => base_dn, :filter => username_filter(username),
          :attributes => attribute_mapping.keys, :return_result => true)
        if result.size > 0
          data = result.detect do |element|
            attribute_mapping.keys.all? {|ldap_name| element[ldap_name] }
          end
          user = User.new
          user.login = transform_username(username)
          attribute_mapping.each do |ldap_name, our_name|
            user.write_attribute(our_name, data[ldap_name].first)
          end

          if user.email.blank?
            user.email = "#{username}.example@#{GitoriousConfig['gitorious_host']}"
          end

          user.password = "left_blank"
          user.password_confirmation = "left_blank"
          user.terms_of_use = '1'
          user.aasm_state = "terms_accepted"
          user.activated_at = Time.now.utc
          user.save!
          # Reset the password to something random
          user.reset_password!
          user
        end
      end

      def build_username(login)
        distinguished_name_template.sub("{}", login)
      end

      private

      def username_filter(username)
        Net::LDAP::Filter.eq(login_attribute, username)
      end
    end
  end
end

