# encoding: utf-8
#--
#   Copyright (C) 2013-2014 Gitorious AS
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
require "fileutils"

class RepositoryHooks

  def self.create(path)
    hooks = RepositoryRoot.expand(".hooks")
    target_path = hooks.relative_path_from(path + "hooks")

    Dir.chdir(path) do
      FileUtils.mkdir_p("hooks")

      %w[pre-receive post-receive update post-update].each do |hook|
        global_hook_path = "#{target_path}/#{hook}"
        local_hook_path = "hooks/#{hook}"
        FileUtils.ln_sf(global_hook_path, local_hook_path) unless File.executable?(local_hook_path)
      end

      global_script_path = "#{target_path}/messaging.rb"
      local_script_path = "hooks/messaging.rb"
      FileUtils.ln_sf(global_script_path, local_script_path) unless File.exist?(local_script_path)
    end
  end

  def self.custom_hook_path(repo_path, name, global_hooks_path = "#{Rails.root}/data/hooks")
    path = "#{repo_path}/hooks/custom-#{name}"
    if File.executable?(path)
      return path
    end

    path = "#{global_hooks_path}/custom-#{name}"
    if File.executable?(path)
      return path
    end

    path = Gitorious::Configuration.get("custom_#{name.gsub('-', '_')}_hook")
    if path && File.executable?(path)
      return path
    end
  end

end
