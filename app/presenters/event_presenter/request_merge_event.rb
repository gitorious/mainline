#--
#   Copyright (C) 2012-2013 Gitorious AS
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

class EventPresenter

  class RequestMergeEvent < self

    def action
      source_repository = event.target.source_repository
      project = source_repository.project
      target_repository = event.target.target_repository

      action_for_event(:event_requested_merge_of) {
        link_to(repo_title(source_repository, project),
          view.project_repository_url(project, source_repository)) +
        " with " + link_to(h(target_repository.name),
          view.project_repository_url(project, target_repository)) +
        " in merge request " + link_to(h(target_repository.url_path) + " " + h("##{target.to_param}"),
          view.project_repository_merge_request_url(project, target_repository, target))
      }
    end

    def body
      link_to(
        truncate(h(target.summary), :length => 100),
        view.polymorphic_url([project, target.target_repository, target])
      )
    end

    def category
      'merge_request'
    end


  end

end
