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

  class CreateBranchEvent < self

    def action
      project = target.project

      if master?
        action_for_event(:event_status_started) {
          [
            "of ",
            view.link_to(h(project.slug), view.project_url(project)),
            "/",
            view.link_to(h(target.name), view.project_repository_url(project, target))
          ].join
        }
      else
        action_for_event(:event_branch_created) do
          view.link_to(view.ref(branch),
            view.project_repository_commits_in_ref_url(project, target, view.ensplat_path(branch))) +
          " on " + view.link_to(h(project.slug), view.project_url(project)) + "/" +
          view.link_to(h(target.name),
            view.project_repository_url(project, target))
        end
      end
    end

    def body
      if master?
        h(event.body)
      else
        super
      end
    end

    def category
      'commit'
    end

    private

    def branch
      data
    end

    def master?
      branch == 'master'
    end

  end

end
