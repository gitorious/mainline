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
auth_configuration_path = File.join(Rails.root, "config", "authentication.yml")

if File.exist?(auth_configuration_path)
  if config = YAML::load_file(auth_configuration_path)[RAILS_ENV]
    Gitorious::Authentication::Configuration.configure(config)
  else
    Gitorious::Authentication::Configuration.use_default_configuration
  end
else
  Gitorious::Authentication::Configuration.use_default_configuration
end
