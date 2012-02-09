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

# This is required because ActiveMessaging actually forcefully loads
# all processors before initializers are run. Hopefully this can go away
# when the vendored ActiveMessaging plugin is removed.
require File.join(Rails.root, "config/initializers/messaging")

class PushProcessor
  include Gitorious::Messaging::Consumer
  consumes "/queue/GitoriousPush"
  attr_reader :user, :repository, :spec

  def on_message(message)
    load_message(message)
    log_message("Got payload: #{spec} from user #{user && user.login}")

    if spec.merge_request?
      log_message("Processing merge request")
      process_merge_request
    elsif repository.wiki?
      log_message("Processing wiki update")
      process_wiki_update
    else
      log_message("Processing regular push")
      process_push
    end
  end

  def process_merge_request
    return if spec.action_delete?
    merge_request.update_from_push!
  end

  def process_push
    ensure_user
    logger = PushEventLogger.new(repository, spec, user)
    logger.create_push_event if logger.create_push_event?
    logger.create_meta_event if logger.create_meta_event?
    repository.register_push
    repository.save
    trigger_hooks unless repository.hooks.blank?
  end

  def trigger_hooks
    generator = Gitorious::WebHookGenerator.new(repository, spec, user)
    generator.generate!
  end

  def process_wiki_update
    ensure_user
    logger = Gitorious::Wiki::UpdateEventLogger.new(repository, spec, user)
    logger.create_wiki_events
  end

  def load_message(message)
    @user = User.find_by_login(message["username"])
    @repository = Repository.find_by_hashed_path(message["gitdir"])
    @spec = PushSpecParser.new(*message["message"].split(" "))
  end

  private
  
  def merge_request
    @repository.merge_requests.find_by_sequence_number!(@spec.ref_name.to_i)
  end

  def ensure_user
    raise "Username was nil" if user.nil?
  end

  def log_message(message)
    logger.info("#{Time.now.to_s(:short)} #{message} to repository #{repository.gitdir}")
  end
end
