# encoding: utf-8
#--
#   Copyright (C) 2009 Marius Mathiesen <marius@shortcut.no>
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
    class Default
      attr_accessor :logger
      
      def initialize(config)
        @logger = ::Rails.logger if !@logger && defined?(::Rails) && Rails.respond_to?(:logger)
        @logger = RAILS_DEFAULT_LOGGER if !@logger && defined?(RAILS_DEFAULT_LOGGER)
        @logger = Logger.new(STDOUT) if !@logger
      end

      # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
      def authenticate(username,password)
        logger.debug "Default authenticating #{username}"
        u = User.find_by_email_with_aliases(username)
        u ||= User.find_by_login(username)
        if u && u.crypted_password == u.encrypt(password)
          u
        else
          nil
        end
      end
    end
  end
end

