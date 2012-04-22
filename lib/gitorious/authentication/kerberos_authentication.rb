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
module Gitorious
  module Authentication
    class KerberosAuthentication
      attr_reader(:realm, :email_domain)

      def initialize(options)
        validate_requirements(options)
        setup_attributes(options)
      end

      def validate_requirements(options)
        # Multi-realm auth is not possible, because we could have username
        # collisions in the user database. It will be possible when Gitorious
        # supports "@" signs in usernames. For now you can only authenticate
        # users from a single Kerberos relam.
        raise ConfigurationError, "Kerberos Realm required" unless options.key?("realm")
      end

      def setup_attributes(options)
        @realm = options["realm"]
        @email_domain = options["email_domain"] || options["realm"].downcase
      end

      # Check if this HTTP user logged in with Kerberos, or not.
      # Apache's mod_auth_kerb will set this environment variable.
      # If the login was unsuccesful, we'll never get this far because
      # mod_auth_kerb will return a 401 error to the browser.
      def valid_kerberos_login(env)
        # We could also check find_username_from_kerberos
        # to ensure the user isn't using an admin principal.
        return (env['HTTP_AUTHORIZATION'] =~ /Negotiate /)
      end

      # The HTTP authentication callback
      def authenticate(credentials)
        return false unless credentials.env && valid_kerberos_login(credentials.env)
        username = find_username_from_kerberos(credentials.env)
        Rails.logger.debug("Kerberos: REMOTE_USER '#{credentials.env['REMOTE_USER']}'.")
        Rails.logger.debug("Kerberos: found username '#{username}'.")
        if existing_user = User.find_by_login(transform_username(username))
          user = existing_user
        else
          user = auto_register(username)
        end
        user
      end

      # Find the Gitorious username from a Kerberos principal in the
      # request.env HTTP object. See the above note about multi-realm and
      # Gitorious username restrictions.
      def find_username_from_kerberos(env)
        # strip off the realm.
        env['REMOTE_USER'].gsub("@#{@realm}", '')
      end

      # Transform a Kerberos username into something that passes Gitorious'
      # username validations (like the LDAPAuthentication module does).
      def transform_username(username)
        username.gsub(".", "-")
      end

      def auto_register(username)
        user = User.new
        user.login = transform_username(username)
        user.email = username + '@' + @email_domain
        Rails.logger.debug("Kerberos: username after transform_username: '#{user.login}'.")
        Rails.logger.debug("Kerberos: email '#{user.email}'.")

        # Again, similar to LDAPAuthentication's implementation
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
  end
end
