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
require "gitorious/configurable_strategy"

module Gitorious
  module Authorization
    module Configuration
      extend Gitorious::ConfigurableStrategy

      def self.default_configuration
        DatabaseAuthorization.new
      end

      def self.configure!
        authorization_configuration_path = File.join(Rails.root, "config", "authorization.yml")

        if File.exist?(authorization_configuration_path)
          if config = YAML::load_file(authorization_configuration_path)[Rails.env]
            Gitorious::Authorization::Configuration.configure(config)
          else
            Gitorious::Authorization::Configuration.use_default_configuration
          end
        else
          Gitorious::Authorization::Configuration.use_default_configuration
        end
        @configured = true
      end

      def self.configured?
        @configured
      end

      configure! unless configured?

    end
  end
end
