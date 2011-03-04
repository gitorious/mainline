# encoding: utf-8
#--
#   Copyright (C) 2011 Gitorious AS
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
module Gitorious
  module Wiki
    class UpdateEventLogger
      def initialize(repository, spec, user)
        @repository = repository
        @spec = spec
        @user = user
      end

      def create_wiki_events
        parser = CommitParser.new
        commits = parser.fetch_from_git(@repository, @spec)
        project = @repository.project
        commits.each do |c|
          c.modified_page_names.each do |p|
            project.create_event(Action::UPDATE_WIKI_PAGE, project, @user, p)
          end
          c.added_page_names.each do |p|
            project.create_event(Action::UPDATE_WIKI_PAGE, project, @user, p)
          end
        end
      end
    end
  end
end
