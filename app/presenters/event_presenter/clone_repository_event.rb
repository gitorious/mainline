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

  class CloneRepositoryEvent < self

    def action
      original_repo = Repository.find_by_id(data.to_i)

      return "" unless original_repo

      project = target.project

      action_for_event(:event_status_cloned) {
        link_to(h(original_repo.url_path), view.project_repository_url(project, original_repo))
      }
    end

    def category
      'repository'
    end

    def body
      'New repository is in ' + link_to(h(target.name), view.project_repository_url(project, target))
    end

  end

end
