# encoding: utf-8
#--
#   Copyright (C) 2011-2014 Gitorious AS
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

class MergeRequestProcessor
  include Gitorious::Messaging::Consumer
  consumes "/queue/GitoriousMergeRequestCreation"

  def on_message(message)
    # Find by id, as we're outside repository scope here
    id = message['merge_request_id'].to_i
    begin
      merge_request = MergeRequest.find(id)
    rescue ActiveRecord::RecordNotFound
      logger.warn("Can't process merge request with id=#{id}, record doesn't exist")
      return
    end

    if !merge_request.target_repository.has_tracking_repository?
      create_tracking_repository(merge_request)
    end
    logger.info("Pushing tracking branch for merge request #{merge_request.to_param} in repository #{merge_request.target_repository.name}'s tracking repository. Project slug is #{merge_request.target_repository.project.slug}")
    update_repositories(merge_request)
  end

  def create_tracking_repository(merge_request)
    repo = merge_request.target_repository
    command = CreateTrackingRepositoryCommand.new(Gitorious::App, repo, true)
    tracking_repo = command.execute(command.build)
    logger.info("Created tracking repository at #{tracking_repo.real_gitdir} for merge request #{merge_request.to_param}")
  end

  def update_repositories(merge_request)
    UpdateMergeRequestTargetRepository.call(merge_request)
    CreateNewMergeRequestVersion.call(merge_request)
  end

end
