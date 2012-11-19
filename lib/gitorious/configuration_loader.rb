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
require "yaml"

module Gitorious
  class ConfigurationLoader
    def initialize(root = File.expand_path(File.join(File.dirname(__FILE__), "../..")))
      @root = root
      @configs = {}
      @hashes = {}
    end

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

      @configs[env] = [cfg, config[env] || {}]
    end

    def hash(env)
      @hashes[env] ||= load(env).inject({}) { |hash, cfg| hash.merge(cfg) }
    end

    def configure_singletons(env)
      require "gitorious"
      load(env).each { |cfg| Gitorious::Configuration.append(cfg) }
      configure_available_singletons(Gitorious::Configuration)
    end

    def configure_available_singletons(config)
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

      config
    end

    private
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
