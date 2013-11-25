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

  class EditWikiPageEvent < self

    def action
      action_for_event(:event_updated_wiki_page) {
        link_to(h(project.slug), view.project_url(project)) + "/" +
        link_to(h(page_name), view.project_page_url(project, page_name))
      }
    end

    def category
      'wiki'
    end

    private

    def page_name
      data
    end

  end

end
