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
require "resque"

def load_consumer(name)
  class_name = name.split("_").collect(&:capitalize).join("")
  Object.const_get("#{class_name}Processor")
rescue NameError => err
  require "processors/#{name}_processor"
end

# Resque backed implementation of the Gitorious messaging API. For use with
# lib/gitorious/messaging
module Gitorious::Messaging::ResqueAdapter
  module Publisher
    QUEUES = {
      "/queue/GitoriousRepositoryCreation" => "repository_creation",
      "/queue/GitoriousRepositoryDeletion" => "repository_deletion",
      "/queue/GitoriousPush" => "push",
      "/queue/_gitoriousSshKeys" => "ssh_key",
      "/queue/GitoriousRepositoryArchiving" => "repository_archiving",
      "/queue/GitoriousEmailNotifications" => "message_forwarding",
      "/queue/GitoriousMergeRequestCreation" => "merge_request",
      "/queue/GitoriousMergeRequestBackend" => "merge_request_git_backend",
      "/queue/GitoriousMergeRequestVersionDeletion" => "merge_request_version",
      "/queue/GitoriousPostReceiveWebHook" => "web_hook"
    }

    # Locate the correct class to pick queue from
    #
    def inject(queue)
      ResqueQueue.new(load_consumer(QUEUES[queue.to_s]))
    end
  end

  module Consumer
    def self.included(klass)
      if klass != Gitorious::Messaging::Consumer
        klass.send(:extend, Macros)
      end
    end

    module Macros
      def consumes(queue, options = {})
        @queue = queue.sub(/\/queue\//, "")
      end

      def perform(message)
        self.new.consume(message)
      end
    end
  end

  class ResqueQueue
    attr_reader :processor

    def initialize(processor)
      @processor = processor
    end

    def publish(payload)
      Resque.enqueue(processor, payload)
    end
  end
end
