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
require "gitorious/on_config"

Gitorious.on_config("memcache.yml") do |settings|
  require "memcache"
  silence_warnings do
    # This may not be the sexiest thing you ever saw, but that's how
    # Rails::Initializer#initialize_cache works
    Gitorious::Application.config.cache_store = :mem_cache_store, settings
    Object.const_set "RAILS_CACHE", ActiveSupport::Cache.lookup_store(Gitorious::Application.config.cache_store, settings)
  end
end
