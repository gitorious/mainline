# encoding: utf-8
#--
#   Copyright (C) 2011-2013 Gitorious AS
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
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

class NewSshKeyProcessor
  include Gitorious::Messaging::Consumer
  consumes "/queue/GitoriousNewSshKey"

  def on_message(message)
    id = message["id"].to_i
    ssh_key = SshKey.find_by_id(id)

    if !ssh_key
      logger.warn("NewSshKeyProcessor executing for non-existent key #{id}")
      return
    end

    logger.debug("NewSshKeyProcessor running for key #{ssh_key}")
    key_file = SshKeyFile.new
    key_file.add_key(SshKeyFile.format(ssh_key))
    ssh_key.ready = true
    ssh_key.save!
  end
end
