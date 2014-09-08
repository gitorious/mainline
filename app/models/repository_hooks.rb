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
    ensure_symlink(Rails.root + "data/hooks", hooks)
    target_path = hooks.relative_path_from(path + "hooks")

    Dir.chdir(path) do
      FileUtils.mkdir_p("hooks")

      %w[pre-receive post-receive update post-update].each do |hook|
        global_hook_path = "#{target_path}/#{hook}"
        local_hook_path = "hooks/#{hook}"
        FileUtils.ln_sf(global_hook_path, local_hook_path) unless File.executable?(local_hook_path)
      end
    end
  end

  private
  def self.ensure_symlink(src, dest)
    return if dest.symlink? && dest.realpath.to_s == src.realpath.to_s
    FileUtils.ln_sf(src.realpath.to_s, dest.expand_path.to_s)
  end
end
