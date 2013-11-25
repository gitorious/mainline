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

  class DeleteTagEvent < self

    def action
      action_for_event(:event_tag_deleted) {
        h(tag_name) + " on " +
        view.link_to(h(project.slug), view.project_url(project)) +
        "/" +
        view.link_to(h(target.name), view.project_repository_url(project, target))
      }
    end

    def category
      'commit'
    end

    private

    def tag_name
      data
    end

  end

end
