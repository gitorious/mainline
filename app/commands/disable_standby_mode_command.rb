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
require 'models/ssh_key_file'
require 'commands/standby_mode_command'

class DisableStandbyModeCommand < StandbyModeCommand

  def execute
    File.unlink(standby_symlink_path) if File.exist?(standby_symlink_path)

    FileUtils.rm_rf(global_hooks_path)
    FileUtils.ln_s(File.expand_path('data/hooks'), global_hooks_path)

    SshKeyFile.regenerate(authorized_keys_path)
  end

end
