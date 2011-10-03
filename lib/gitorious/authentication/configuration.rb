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
    module Configuration
      
      def self.configure(user_configuration)
        use_default_configuration unless user_configuration["disable_default"]
        Array(user_configuration["methods"]).each { |m| add_custom_method(m)}
      end

      def self.use_default_configuration
        add_authentication_method Gitorious::Authentication::DatabaseAuthentication.new
      end

      def self.add_authentication_method(method)
        authentication_methods << method unless method_added?(method.class)
      end

      def self.method_added?(method_class)
         authentication_methods.any? {|m| m.class == method_class}
      end

      def self.add_custom_method(configuration)
        method_class = configuration["adapter"].constantize
        add_authentication_method(method_class.new(configuration))
      end

      def self.authentication_methods
        @authentication_methods ||= []
      end      
    end

    class ConfigurationError < StandardError
    end
  end
end
