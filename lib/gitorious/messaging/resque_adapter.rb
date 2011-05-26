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
      ResqueQueue.new(Object.const_get("#{QUEUES[queue.to_s]}Processor"))
    end
  end

  module Consumer
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
