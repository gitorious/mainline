# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
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

# This is required because ActiveMessaging actually forcefully loads
# all processors before initializers are run. Hopefully this can go away
# when the vendored ActiveMessaging plugin is removed.
require File.join(Rails.root, "config/initializers/messaging")

class SshKeyProcessor
  include Gitorious::Messaging::Consumer
  consumes "/queue/GitoriousSshKeys"

  def on_message(message)
    command = message["command"]
    target_id = message["target_id"]
    args = message["arguments"]

    unless %w(add_to_authorized_keys delete_from_authorized_keys).include?(command)
      raise "Unknown command"
    end

    logger.debug("Processor sending message: #{command} #{args}")
    SshKey.send(command, *args)

    if target_id
      if obj = SshKey.find_by_id(target_id.to_i)
        obj.ready = true
        obj.save!
      end
    end
  end
end
