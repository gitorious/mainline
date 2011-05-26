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

# Synchronous implementation (i.e. no separate poller/worker required). of the
# Gitorious messaging API. For use with lib/gitorious/messaging.
# Note that this implementation is only suitable for small setups, think of it
# as "Gitorious light" - fewer movable parts, but also less performant.
#
module Gitorious::Messaging::SyncAdapter
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
      @queues ||= {}
      @queues[queue] = SyncQueue.new(Object.const_get("#{QUEUES[queue.to_s]}Processor"))
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
        # Noop, there are no subscribers as messages are
        # consumed synchronously on publish
      end
    end
  end

  class SyncQueue
    attr_reader :processor

    def initialize(processor)
      @processor = processor
    end

    def publish(payload)
      processor.new.consume(payload)
    end
  end
end
