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
  # Application-wide configuration settings.
  #
  module Configuration
    def self.prepend(settings)
      configs.unshift(settings)
      settings
    end

    def self.append(settings)
      configs.push(settings)
      settings
    end

    def self.prune(settings)
      @@configs = configs.reject { |c| c == settings }
    end

    def self.get(key, default = nil)
      env_key = "GITORIOUS_#{key.upcase}"
      return ENV[env_key] if ENV.key?(env_key)
      settings = configs.detect { |c| c.key?(key) }
      return settings[key] if settings
      return yield if block_given? && default.nil?
      default
    end

    private
    def self.configs
      @@configs ||= []
    end
  end
end
