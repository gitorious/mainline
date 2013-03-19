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
require "mutations"

class SshKeyCreator < Mutations::Command
  required do
    string :key
    integer :user_id
  end

  def execute
    ssh_key = User.find(user_id.to_i).ssh_keys.new
    ssh_key.key = key

    if ssh_key.save!
      ssh_key.publish_creation_message
    end

    ssh_key
  rescue ActiveRecord::RecordInvalid
    messages = ssh_key.errors.full_messages
    ssh_key.errors.each { |k, m| add_error(k, :validation, messages.shift) }
  end
end
