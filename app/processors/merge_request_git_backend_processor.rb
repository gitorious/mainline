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
class MergeRequestGitBackendProcessor < ApplicationProcessor

  subscribes_to :merge_request_backend_updates

  def on_message(message)
    verify_connections!
    @body = ActiveSupport::JSON.decode(message)
    send("do_#{action}")
  end

  def action
    @body["action"].to_sym
  end

  def source_repository
    @source_repository ||= Repository.find(@body["source_repository_id"])
  end

  def target_repository
    @target_repository ||= Repository.find(@body["target_repository_id"])
  end

  def delete_target_repository_ref
    source_repository.git.git.push({:timeout => false},
      target_repository.full_repository_path,
      ":#{@body['merge_branch_name']}")
  end

  private
  def do_delete
    logger.info("Deleting tracking branch #{@body['merge_branch_name']} for merge request " +
      "in target repository #{@body['target_name']}")
    begin
      delete_target_repository_ref
    rescue Grit::NoSuchPathError => e
      logger.error "Could not find Git path. Message is #{e.message}"
    rescue ActiveRecord::RecordNotFound => rfe
      logger.error "Could not find repository, it may have been deleted. Message is #{rfe.message}"
    end
  end
end
