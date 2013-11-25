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

  class PushEvent < PushSummaryEvent

    def action
      action_for_event(:event_pushed, :link => repository_link)
    end

    def body
      if commits
        super
      else
        ''
      end
    end

    def repository_link
      link_to("#{repo_title(repository, project)}", view.project_repository_url(project, repository))
    end

    def commit_count
      events.size
    end

    def repository
      target
    end

    private

    def initialize_commits
      super if events.size > 0
    end

    def initialize_event_data
      @event_data = {
        :start_sha    => events.first && events.first.data,
        :end_sha      => events.last && events.last.data,
        :commit_count => events.size,
        :branch       => data
      }
    end

  end

end
