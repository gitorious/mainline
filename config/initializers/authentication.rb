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
require "gitorious/authentication"
auth_configuration_path = ENV['GTS_AUTHENTICATION_YML'] || Rails.root + "config/authentication.yml"

if File.exist?(auth_configuration_path)
  config = Gitorious::ConfigurationReader.read(auth_configuration_path)

  if config && config.key?(Rails.env)
    config = config[Rails.env]
  end

  if config
    Gitorious::Authentication::Configuration.configure(config)
  else
    Gitorious::Authentication::Configuration.use_default_configuration
  end
else
  Gitorious::Authentication::Configuration.use_default_configuration
end
