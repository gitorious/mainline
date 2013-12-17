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

class UserMessages
  def self.for(user)
    new(user, Message.involving_user(user))
  end

  def initialize(user, messages)
    @user = user
    @messages = messages
  end

  def find(id)
    @messages.find(id)
  end

  def all
    @messages.sort_by(&:created_at).reverse
  end

  def sent
    all.select { |msg| msg.sender == user }
  end

  private

  attr_reader :user
end
