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
  class Configurable
    attr_reader :deprecation_listeners, :deprecations, :transformations, :configs

    def initialize(env_prefix = nil)
      @env_prefix = env_prefix
      @deprecation_listeners = []
      @deprecations = {}
      @transformations = {}
      @configs = []
    end

    def prepend(settings)
      configs.unshift(settings)
      settings
    end

    def append(settings)
      configs.push(settings)
      settings
    end

    def prune(settings)
      @configs = configs.reject { |c| c == settings }
    end

    def get(key, default = nil)
      ([key] + aliases(key)).each do |k|
        value = lookup(k)
        issue_deprecation(k, key, deprecations[k]) if k != key && !value.nil?
        if !value.nil?
          value = transformations[k].call(value) unless transformations[k].nil?
          return value
        end
      end
      return yield if block_given? && default.nil?
      default
    end

    def override(settings = {})
      configs = @configs
      @configs = [settings]

      begin
        yield(self)
      ensure
        @configs = configs
      end
    end

    def rename(old, new, comment = nil, &block)
      aliases(new) << old
      deprecations[old] = comment
      transformations[old] = block
      new
    end

    def aliases(key)
      @aliases ||= {}
      @aliases[key] ||= []
    end

    def on_deprecation(&block)
      deprecation_listeners << block
    end

    private
    def lookup(key)
      env_key = "#{@env_prefix}_#{key.to_s.upcase}"
      return ENV[env_key] if !@env_prefix.nil? && ENV.key?(env_key)
      settings = configs.detect { |c| c.key?(key) }
      return settings[key] unless settings.nil?
    end

    def issue_deprecation(old, new, comment)
      deprecation_listeners.each { |l| l.call(old, new, comment) }
    end
  end
end
