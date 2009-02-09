#--
#   Copyright (C) 2007, 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Marius Mathiesen <marius.mathiesen@gmail.com>
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
class SshKeyProcessor < ApplicationProcessor
  subscribes_to :ssh_key_generation

  def on_message(message)
    json = ActiveSupport::JSON.decode(message)
    logger.debug("Processor processing message #{json}")
    if %w(add_to_authorized_keys delete_from_authorized_keys).include?(json['command'])
      logger.debug("Processor sending message: #{json['command']} #{json['arguments']}")
      SshKey.send(json['command'], *json['arguments'])
      if target_id = json['target_id']
        if obj = json['target_class'].constantize.find_by_id(target_id.to_i)
          obj.ready = true
          obj.save!
        end
      end
    else
      raise "Unknown command"
    end
  end
end