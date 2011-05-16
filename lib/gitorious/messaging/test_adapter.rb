# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
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

# In-memory/noop implementation of the Gitorious messaging API. For use with
# lib/gitorious/messaging in tests.
#
module Gitorious::Messaging::TestAdapter
  @@messages = {}

  def self.clear
    @@messages = {}
  end

  def self.messages_on(queue)
    @@messages[queue] || []
  end

  def self.publish(queue, message)
    (@@messages[queue] ||= []) << JSON.parse(message)
  end

  module Publisher
    def inject(queue)
      Queue.new { |msg| Gitorious::Messaging::TestAdapter.publish(queue, msg) }
    end
  end

  class Queue
    def initialize(&block)
      @publisher = block
    end

    def publish(payload)
      @publisher.call(payload)
    end
  end
end
