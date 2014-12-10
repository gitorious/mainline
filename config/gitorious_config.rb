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

# Main configuration of the Gitorious application from the config/gitorious.yml
# configuration file.
#
# Gitorious configuration used to be a hash (GitoriousConfig) that was mostly
# used run-time to look up values in the underlying file. In Gitorious 3.x,
# configuration is a boot-time concern, and the underlying key/value data should
# rarely be accessed run-time.
#
# This initializer uses Gitorious::ConfigurationLoader to load the contents of
# config/gitorious.yml into the Gitorious::Configuration singleton and wire up
# other singletons, such as RepositoryRoot.default_base_path.
#
# Settings in config/gitorious.yml are mainly used to build objects exposed via
# the Gitorious application module, such as Gitorious.git_daemon (which has
# methods like port, host, path, url(path) etc) and configure certain
# class-variables, such as ProjectLicense.all. If you ever need to look up
# the same key via Gitorious::Configuration.get in more than one place, this
# lookup should be protected behind some sort of abstraction.
#
# When this initializer is not run and you need access to Gitorious
# configuration data, please look into lib/gitorious/configuration_loader.rb
if !defined?(Gitorious::Configuration) || !Gitorious.configured?
  require "gitorious/configuration_loader"
  require "gitorious/messaging"

  env = "test"
  loader = Gitorious::ConfigurationLoader.new

  if defined?(Rails)
    loader.require_configurable_singletons!
    env = Rails.env
    loader = Gitorious::ConfigurationLoader.new(Rails.root)
  end

  # Wire up the global Gitorious::Configuration singleton with settings
  config = loader.configure_application!(env)

  config.append("git_version" => `#{Gitorious.git_binary} --version`.chomp)

  if !Gitorious.public? || Gitorious.private_repositories?
    require Rails.root + "app/middlewares/dolt_auth_middleware"
    Gitorious::Application.middleware.use DoltAuthMiddleware
    require Rails.root + "app/middlewares/dolt_cache_middleware"
    Gitorious::Application.middleware.use DoltCacheMiddleware
  end
end
