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
    @body = ActiveSupport::JSON.decode(message)
    send("do_#{action}")
  end

  def action
    @body["action"].to_sym
  end

  def merge_request
    @merge_request ||= MergeRequest.find(@body["merge_request_id"])
  end

  private
  def do_delete
    logger.info("Deleting tracking branch #{merge_request.merge_branch_name} for merge request in target repository #{merge_request.target_repository.id}")
    begin
      merge_request.delete_target_repository_ref
    rescue Grit::NoSuchPathError => e
      logger.error "Could not find Git path. Message is #{e.message}"
    end
    merge_request.destroy
  end
end
