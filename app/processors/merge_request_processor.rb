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
    json = ActiveSupport::JSON.decode(message)
    merge_request_id = json['merge_request_id']
    merge_request = MergeRequest.find(merge_request_id)
    if merge_request.target_repository.has_merge_request_repository?
      create_merge_request_branch(merge_request)
    else
      post_repository_creation_message(merge_request)
    end
  end
  
  # We're doing some pipelining here. The special repository for merge requests should be created
  # when needed. Therefore, we send another message to the separate queue for creation of repositories 
  # when necessary, and append information to the message that we want one back as soon as it's done
  def post_repository_creation_message(merge_request)
    merge_request_repo = merge_request.target_repository.create_merge_request_repository
    
    options = {:target_class => 'Repository', :target_id => merge_request_repo.id}
    options[:command] = 'clone_git_repository'
    options[:arguments] = [merge_request_repo.real_gitdir, merge_request.target_repository.real_gitdir]
    options[:resend_message_to] = {
      :destination => 'mirror_merge_requests', 
      :with => {:merge_request_id => merge_request.id}
    }
    publish :create_repo, options.to_json    
  end
  
  def create_merge_request_branch(merge_request)
    merge_request.push_to_merge_request_repository!
    logger.info("Creating merge request branch for MR no #{merge_request.id}")
  end
end