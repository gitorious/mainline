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

  class CommitEvent < self

    def action
      case kind
      when Repository::KIND_WIKI
        action_for_event(:event_status_push_wiki) do
          "to " + view.link_to(h(project.slug), view.project_url(project)) +
          "/" + view.link_to(h(view.t("views.layout.pages")), view.project_pages_url(project))
        end
      when 'commit'
        action_for_event(:event_status_committed) do
          view.link_to(
            data[0,8],
            view.project_repository_commit_url(project, repo, data)) +
          " to " + view.link_to(h(project.slug), view.project_url(project))
        end
      else
        action_for_event(:event_status_committed) do
          view.link_to(
            h(data[0,8]),
            view.project_repository_commit_url(project, repo, data)) +
          " to " + view.link_to(h(project.slug), view.project_url(project))
        end
      end
    end

    def body
      case kind
      when Repository::KIND_WIKI
        h(truncate(event.body, :length => 150))
      else
        view.link_to(h(truncate(event.body, :length => 150)),
                     view.project_repository_commit_url(project, target, data))
      end
    end

    def category
      case kind
      when Repository::KIND_WIKI then 'wiki'
      else
        'commit'
      end
    end

    def repo
      repo = event.target
    end

    def project
      repo.project
    end

  end

end
