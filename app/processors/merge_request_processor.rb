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
class MergeRequestProcessor < ApplicationProcessor
  subscribes_to :mirror_merge_request

  def on_message(message)
    verify_connections!
    json = ActiveSupport::JSON.decode(message)
    merge_request_id = json['merge_request_id']
    merge_request = MergeRequest.find(merge_request_id)
    if !merge_request.target_repository.has_tracking_repository?
      create_tracking_repository(merge_request)
    end
    logger.info("Pushing tracking branch for merge request #{merge_request.to_param} in repository #{merge_request.target_repository.name}'s tracking repository. Project slug is #{merge_request.target_repository.project.slug}")
    merge_request.push_to_tracking_repository!(true)
  end
  
  def create_tracking_repository(merge_request)
    tracking_repo = merge_request.target_repository.create_tracking_repository
    logger.info("Creating tracking repository at #{tracking_repo.real_gitdir} for merge request #{merge_request.to_param}")
    Repository.clone_git_repository(
      tracking_repo.real_gitdir, 
      merge_request.target_repository.real_gitdir,
      {:skip_hooks => true})
  end
end
