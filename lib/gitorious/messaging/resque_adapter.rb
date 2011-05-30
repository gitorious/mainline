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

# Resque backed implementation of the Gitorious messaging API. For use with
# lib/gitorious/messaging
module Gitorious::Messaging::ResqueAdapter
  module Publisher
    QUEUES = {
      "/queue/GitoriousRepositoryCreation" => "RepositoryCreation",
      "/queue/GitoriousRepositoryDeletion" => "RepositoryDeletion",
      "/queue/GitoriousPush" => "Push",
      "/queue/GitoriousSshKeys" => "SshKey",
      "/queue/GitoriousRepositoryArchiving" => "RepositoryArchiving",
      "/queue/GitoriousEmailNotifications" => "MessageForwarding",
      "/queue/GitoriousMergeRequestCreation" => "MergeRequest",
      "/queue/GitoriousMergeRequestBackend" => "MergeRequestGitBackend",
      "/queue/GitoriousMergeRequestVersionDeletion" => "MergeRequestVersion",
      "/queue/GitoriousPostReceiveWebHook" => "WebHook"
    }

    # Locate the correct class to pick queue from
    #
    def inject(queue)
      ResqueQueue.new(queue, "#{QUEUES[queue.to_s]}Processor")
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
    attr_reader :queue, :processor

    def initialize(queue, processor)
      @queue = queue
      @processor = processor
    end

    def publish(payload)
      Resque.push(queue, :class => processor, :args => [payload])
    end
  end
end
