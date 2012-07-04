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
require "gitorious/authentication/configuration"

module Gitorious
  module Authentication
    # Returns the first matching User instance from all authentication methods
    def self.authenticate(credentials)
      Configuration.authentication_methods.each do |authenticator|
        if result = authenticator.authenticate(credentials)
          return result
        end
      end
      return nil
    end

    module UsernameTransformation
      def initialize_options(options)
        @login_replace_char = options['login_replace_char'] || '-'
        @login_strip_domain = options['login_strip_domain']

        super if defined?(super)
      end

      def initialize(options)
        initialize_options(options)
      end

      def transform_username(username)
        username = username.split('@')[0] if @login_strip_domain
        username.gsub(/[^a-z0-9\-]/i, @login_replace_char)
      end
    end

    module AutoRegistration
      def initialize_options(options)
        @email_domain = options['email_domain']

        super if defined?(super)
      end

      def initialize(options)
        initialize_options(options)
      end

      def authenticate(credentials)
        username = get_login(credentials)
        return unless username

        username = transform_username(username) if defined?(transform_username)
        return if username.empty?

        User.find_by_login(username) || auto_register(username, credentials)
      end

      def auto_register(username, credentials)
        # If the authentication plugin hasn't set at least
        # the email address, auto registration isn't possible.
        return if (attributes = get_attributes(credentials))['email'].blank?

        user = User.new
        user.login = username

        attributes.each do |name, val|
            if name == 'email' and !(@email_domain.blank?)
                user.email = "#{val.split('@')[0]}@#{@email_domain}"
            else
                user.write_attribute(name, val)
            end
        end

        user.password = 'left_blank'
        user.password_confirmation = 'left_blank'
        user.terms_of_use = '1'
        user.aasm_state = 'terms_accepted'
        user.activated_at = Time.now.utc
        user.save!
        # Reset the password to something random
        user.reset_password!
        user
      end

      def get_login(credentials)
        credentials.username
      end

      def get_attributes(credentials)
        {}
      end
    end
  end
end
