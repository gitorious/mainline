# encoding: utf-8
#--
#   Copyright (C) 2009 Nokia Corporation and/or its subsidiary(-ies)
#   Copyright (C) 2008 Johan Sørensen <johan@johansorensen.com>
#   Copyright (C) 2008 Tor Arne Vestbø <tavestbo@trolltech.com>
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

module MergeRequestsHelper
  def link_to_status(repository, status)
    if params[:status].blank? && status == "open"
      link_to_selected_status(repository, status)
    elsif params[:status] == status
      link_to_selected_status(repository, status)
    else
      link_to_not_selected_status(repository, status)
    end
  end
  
  def link_to_not_selected_status(repository, status)
    link_to(status.titlecase, repo_owner_path(repository, 
      :project_repository_merge_requests_path, repository.project, repository, {:status => status}))
  end
  
  def link_to_selected_status(repository, status)
    link_to(status.titlecase, repo_owner_path(repository, 
      :project_repository_merge_requests_path, repository.project, repository, {:status => status}),
      {:class => "selected"})
  end
end
