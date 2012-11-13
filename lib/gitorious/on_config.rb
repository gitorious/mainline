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
  # If the file Rails.root + config/config_file exists, load this as a
  # YAML file, fetch the section under Rails.env and yield these settings
  #
  # See config/initializers/resque.rb / config/resque.yml for an
  # example
  def self.on_config(config_file)
    path = Rails.root + "config/#{config_file}"
    if path.exist?
      settings = YAML::load_file(path)[Rails.env]
      yield settings if settings
    end
  end
end
