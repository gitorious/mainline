# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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

class RepositoryHooks
  def self.create(path)
    hooks = RepositoryRoot.expand(".hooks")
    ensure_symlink(Rails.root + "data/hooks", hooks)

    local_hooks = path + "hooks"
    return if local_hooks.exist?

    target_path = hooks.relative_path_from(path)
    Dir.chdir(path) do
      FileUtils.ln_s(target_path, "hooks")
    end
  end

  private
  def self.ensure_symlink(src, dest)
    return if dest.symlink? && dest.realpath.to_s = src.realpath.to_s
    FileUtils.ln_sf(src.realpath.to_s, dest.expand_path.to_s)
  end
end
