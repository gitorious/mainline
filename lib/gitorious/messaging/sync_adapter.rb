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

# Synchronous implementation (i.e. no separate poller/worker required). of the
# Gitorious messaging API. For use with lib/gitorious/messaging.
# Note that this implementation is only suitable for small setups, think of it
# as "Gitorious light" - fewer movable parts, but also less performant.
#
module Gitorious::Messaging::SyncAdapter
  def self.load_env
    dirname = File.dirname(__FILE__)
    require File.expand_path(File.join(dirname, "../../../config/environment"))
  end

  def self.load_processor(identifier)
    self.load_env if !defined?(Rails)
    queue = Publisher::QUEUES[identifier.to_s]
    require "processors/#{queue}_processor"
    Object.const_get("#{queue.split("_").collect(&:capitalize)}Processor")
  end

  module Publisher
    QUEUES = {
      "/queue/GitoriousRepositoryCreation" => "repository_creation",
      "/queue/GitoriousRepositoryDeletion" => "repository_deletion",
      "/queue/GitoriousPush" => "push",
      "/queue/GitoriousSshKeys" => "ssh_key",
      "/queue/GitoriousRepositoryArchiving" => "repository_archiving",
      "/queue/GitoriousEmailNotifications" => "message_forwarding",
      "/queue/GitoriousMergeRequestCreation" => "merge_request",
      "/queue/GitoriousMergeRequestBackend" => "merge_request_git_backend",
      "/queue/GitoriousMergeRequestVersionDeletion" => "merge_request_version",
      "/queue/GitoriousPostReceiveWebHook" => "web_hook"
    }

    # Locate the correct class to pick queue from
    #
    def queue(queue)
      @queues ||= {}
      @queues[queue] = SyncQueue.new(Gitorious::Messaging::SyncAdapter.load_processor(queue))
    end

    def do_publish(queue, message)
      queue(queue).publish(message)
    end
  end

  module Consumer
    def self.included(klass)
      klass.send(:extend, self) if klass != Gitorious::Messaging::Consumer
    end

    def consumes(queue, options = {})
      # Noop, there are no subscribers as messages are
      # consumed synchronously on publish
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
