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
require "net/http"
require "nokogiri"
require "gitorious/authentication/crowd/api"
require "gitorious/authentication/crowd/user"

module Gitorious
  module Authentication
    class CrowdAuthentication
      def initialize(opt)
        validate_requirements(opt)
        @client = CrowdAPI.new(opt["application"], opt["password"], opt);
      end

      def authenticate(credentials)
        @client.authenticate(credentials.username, credentials.password) do |status, body|
          return nil unless status.to_i == 200
          User.find_by_login(CrowdUser.map_username(credentials.username)) ||
            CrowdUser.from_xml_string(body).to_user
        end
      end

      private
      def validate_requirements(options)
        verify("application", options)
        verify("password", options)
      end

      def verify(attribute, options)
        unless options.key?(attribute)
          raise ConfigurationError, "#{attribute.capitalize} required"
        end
      end
    end
  end
end
