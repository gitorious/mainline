# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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

# ThinkingSphinx indexes are defined outside the model declarations,
# as they should not be required in order to use the database tables
module Gitorious
  module SearchIndex
    def self.setup
      Project.define_index do
        indexes title
        indexes description
        indexes slug
        indexes user.login, :as => :user
        indexes tags.name, :as => :category
      end

      Repository.define_index do
        indexes name
        indexes description
        indexes project.slug, :as => :project
        where "kind in (#{[Repository::KIND_PROJECT_REPO, Repository::KIND_TEAM_REPO, Repository::KIND_USER_REPO].join(',')})"
      end


      Comment.define_index do
        indexes body
        indexes user.login, :as => "commented_by"
      end


      MergeRequest.define_index do
        indexes proposal
        indexes status_tag, :as => "status"
        indexes user.login, :as => "proposed_by"
        where "status != 0"
      end
    end
  end
end
