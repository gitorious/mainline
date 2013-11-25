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

  class ReopenMergeRequestEvent < self

    def action
      source_repository = event.target.source_repository
      project = source_repository.project

      action_for_event(:event_reopened_merge_request) {
        "in " +
        link_to(h(project.title), view.project_url(project)) + "/" +
        link_to(h(source_repository.name), view.project_repository_url(project, source_repository))
      }
    end

    def body
      link_to(
        truncate(h(event.target.proposal), :length => 100),
        view.polymorphic_url([project, target_repository, event.target])
      )
    end

    def category
      'merge_request'
    end

  end

end
