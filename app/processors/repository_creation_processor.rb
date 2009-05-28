# encoding: utf-8
#--
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
class RepositoryCreationProcessor < ApplicationProcessor
  subscribes_to :create_repo

  def on_message(message)
    message_hash = ActiveSupport::JSON.decode(message)
    target_class  = message_hash['target_class']
    target_id     = message_hash['target_id']
    command       = message_hash['command']
    arguments     = message_hash['arguments']

    logger.info("Processor: #{target_class}(#{target_id.inspect})::#{command}(#{arguments.inspect}..)")
    target_class.constantize.send(command, *arguments)
    unless target_id.blank?
      obj = target_class.constantize.find_by_id(target_id)
      if obj && obj.respond_to?(:ready)
        obj.ready = true
        obj.save!
      end
    end
  end
end