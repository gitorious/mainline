# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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

# Look up values from multiple hashes in prioritized order, or use
# default values when no hash has a value for the corresponding key.
#
# If given an "env_prefix", the configurable will prefer environment
# variables if they exist. Given the prefix "GTS", attempting to look
# up "some_key" will result in the configurable trying the
# GTS_SOME_KEY environment variable before consulting any of the
# provided hashes.
#
# When Gitorious' initializers have run, Gitorious::Configuration is
# a globally shared instance of this class, used to interact with
# config/gitorious.yml.
#
# Sample usage:
#
#     # Look for env variables like $GTS_*
#     configurable = Gitorious::Configurable.new("GTS")
#
#     # Add some settings
#     configurable.append("variety" => "Jalapeno", "SHU" => "50000")
#     configurable.append("variety" => "Thai", "origin" => "Americas")
#
#     # Hashes are treated like a queue - first come, first serve.
#     # Hashes can be prepended to this queue if they are preferred
#     # sources:
#     shu_override = configurable.prepend("SHU" => "10000")
#
#     # Look up some values
#     configurable.get("variety") # "Jalapeno"
#     configurable.get("SHU")     # "10000"
#     configurable.get("origin")  # "Americas"
#
#     # Prune that SHU override we prepended:
#     configurable.prune(shu_override)
#
#     # Look up SHU
#     configurable.get("SHU")     # "50000"
#
# The configurable also supports renaming settings, and provides a
# mechanism for reacting to attempts at using the old/deprecated
# names:
#
#     configurable = Gitorious::Configurable.new
#     configurable.append("variety" => "Jalapeno", "heat" => "10000")
#     configurable.rename("heat", "SHU", "It's now called Scoville heat units")
#
#     configurable.on_deprecation do |old, new, comment|
#       $stderr.puts "Ohoi there! #{old} changed to #{new}: #{comment}"
#     end
#
#     configurable.get("heat") # "10000", and prints the above warning
#
# Renames can also have a transformation associated with them:
#
#     configurable.append("length" => "2in")
#     configurable.rename("length", "length_in_cm", "Metric FTW") do |old|
#       old.to_f * 2.54
#     end
#
#     configurable.get("length_in_cm") # 5.08
#
module Gitorious
  class Configurable
    attr_reader :deprecation_listeners, :deprecations, :transformations, :configs

    # `env_prefix` is the prefix used when looking for environment
    # variables. If nil, environment variables will not be used.
    #
    def initialize(env_prefix = nil)
      @env_prefix = env_prefix
      @deprecation_listeners = []
      @deprecations = {}
      @transformations = {}
      @configs = []
    end

    # Prepend a hash of settings, making these settings the preferred
    # settings. Returns the settings. Keep a reference to them if you
    # later need to prune them.
    def prepend(settings)
      configs.unshift(settings)
      settings
    end

    # Append a hash of settings, making these the least preferred
    # settings (i.e., if any other hash contains settings for the same
    # key, those will be preferred). Returns the settings. Keep a
    # reference to them if you later need to prune them.
    def append(settings)
      configs.push(settings)
      settings
    end

    # Prune a hash from the available settings.
    def prune(settings)
      @configs = configs.reject { |c| c == settings }
    end

    # Look up settings. Optionally provide a default that will be
    # returned if there is no value provided for this key.
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

    # Temporarily override settings. Pass in a hash that will be
    # prepended. The method will then yield itself to a block, and
    # when the block completes, the settings are pruned. Provided
    # settings will be pruned even if an exception is raised in the
    # block.
    def override(settings = {})
      configs = @configs
      @configs = [settings]

      begin
        yield(self)
      ensure
        @configs = configs
      end
    end

    # "Rename" a setting. Provide the old name and the new. Optionally
    # provide a comment that will be yielded to deprecation listeners.
    # Optionally provide a block that will be called with an "old"
    # value. The return value of the block is taken as the converted
    # new value. Useful when settings change name _and_ semantics.
    def rename(old, new, comment = nil, &block)
      aliases(new) << old
      deprecations[old] = comment
      transformations[old] = block
      new
    end

    # Add a block to be called whenever a setting is looked up by its
    # old name. E.g. get("new_name") results in fetching out a value
    # from a hash by its "old_name". Block is called with old name,
    # new name and a comment (which may be nil).
    def on_deprecation(&block)
      deprecation_listeners << block
    end

    def aliases(key)
      @aliases ||= {}
      @aliases[key] ||= []
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
