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
require "pathname"
require "yaml"

# See also config/initializers/gitorious_config.yml for more information about
# how Gitorious is configured.
#
# Load configuration from config/gitorious.yml) and optionally configure
# the application's singletons within the Rails process.
#
# Most of the time, this loader is used by
# config/initializers/gitorious_config.rb, which configures the application. In
# cases where you are not running initializers but still need access to the
# contents of gitorious.yml, you should look into using this class.
#
# This class can be used at two "levels of configuration":
#
# 1. Loading the contents of config/gitorious.yml into Gitorious::Configuration
# 2. Optionally also configure various application singletons, such as
#    RepositoryRoot.default_base_path
#
# Usage:
#
#     loader = Gitorious::ConfigurationLoader.new
#     # This step is optional - if you are going to call this method, you should
#     # require config/environment.rb first, or configure the load path properly
#     # some other way
#     loader.require_configurable_singletons!
#     loader.configure_application!(env)
#
#     Gitorious.git_client.port # git_client_port from gitorious.yml
#
module Gitorious
  class ConfigurationLoader
    # Initialize the loader with a root directory. Defaults to the
    # Gitorious application root.
    def initialize(root = File.expand_path(File.join(File.dirname(__FILE__), "../..")))
      @root = root
      @configs = {}
      @hashes = {}
    end

    # Configures the application by populating Gitorious::Configuration with
    # configuration settings found in config/gitorious.yml. It also configures
    # any of the following singletons that are available (for convenience, they
    # can all be loaded by calling require_configurable_singletons! first):
    #
    #   RepositoryRoot
    #   ProjectLicense
    #   ProjectProposal
    #   Gitorious::Messaging
    #
    def configure_application!(env)
      require "gitorious"
      load(env).each { |cfg| Gitorious::Configuration.append(cfg) }
      Gitorious.configured!
      configure_available_singletons(Gitorious::Configuration, env)
    end

    # Require all configurable singletons. If Rails is not available,
    # requiring ProjectProposal is not attempted.
    #
    def require_configurable_singletons!
      # Load so configure_application! will configure them
      root = Pathname(@root)
      require(root + "app/models/repository_root")
      require(root + "app/models/project_license")
      require(root + "app/models/project_proposal") if defined?(ActiveRecord)
      require(root + "lib/gitorious/messaging")
    end

    def configure_available_singletons(config, env = "production")
      if defined?(RepositoryRoot)
        RepositoryRoot.default_base_path = config.get("repository_base_path")
        RepositoryRoot.shard_dirs! if config.get("enable_repository_dir_sharding")
      end

      if defined?(ProjectLicense)
        licenses = config.get("licenses", ProjectLicense::DEFAULT)
        ProjectLicense.licenses = licenses
        ProjectLicense.default = config.get("default_license", ProjectLicense.first.name)
      end

      if config.get("enable_project_approvals") && defined?(ProjectProposal)
        ProjectProposal.enable
      end

      if defined?(Gitorious::Messaging)
        default_adapter = env == "test" ? "test" : "resque"
        Gitorious::Messaging.adapter = config.get("messaging_adapter", default_adapter)
        Gitorious::Messaging.configure(Gitorious::Messaging.adapter) unless Gitorious::Messaging::Consumer.configured?
      end

      config
    end

    private
    def load(env)
      return @configs[env] if @configs[env]
      cfg = YAML::load_file(File.join(@root, "config/gitorious.yml"))

      if cfg.key?("test")
        log_error(<<-EOF)
Your config/gitorious.yml file contains settings for the test
environment. As of Gitorious 3 this is deprecated - test settings have
moved to test/gitorious.yml. Please remove all test
settings from your configuration file to avoid any unpleasant
surprises.
    EOF
      end

      if env == "test"
        cfg = YAML::load_file(File.join(@root, "test/gitorious.yml"))
        if cfg.key?("production") || cfg.key?("development") || cfg.key?("test")
          log_error(<<-EOF)
The test configuration file test/gitorious.yml is not
supposed to contain settings groups - it should just contain top-level
settings applicable to the test environment. Please revise this file.
Tests may not work as intended.
      EOF
        end

        return (@configs[env] = [cfg])
      end

      config = {
        "production" => cfg.delete("production"),
        "development" => cfg.delete("development")
      }
      @configs[env] = [config[env] || {}, cfg]
    end

    def log_error(message)
      message = "WARNING!\n========\n#{message}\n"

      if defined?(Rails) && Rails.respond_to?(:logger)
        Rails.logger.error(message)
      else
        puts message
      end
    end
  end
end
