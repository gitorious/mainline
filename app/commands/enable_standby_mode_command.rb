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

class EnableStandbyModeCommand

  def initialize(authorized_keys_path, public_path,
                 global_hooks_path = RepositoryRoot.expand(".hooks"))
    @authorized_keys_path = authorized_keys_path
    @public_path = public_path
    @global_hooks_path = global_hooks_path
  end

  def execute
    master_public_key = Gitorious::Configuration.get("master_public_key")

    if master_public_key
      FileUtils.ln_s(standby_file_path, standby_symlink_path)

      FileUtils.rm_rf(@global_hooks_path)
      FileUtils.ln_s('/dev/null', @global_hooks_path)
      key_file = SshKeyFile.new(@authorized_keys_path)
      key_file.truncate!
      key_file.add_key(SshKeyFile.format_master_key(master_public_key))

      true
    else
      false
    end
  end

  private

  def standby_file_path
    File.join(@public_path, 'standby.html')
  end

  def standby_symlink_path
    File.join(@public_path, 'system', 'standby.html')
  end
end
