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
module Gitorious
  module Authorization
    class CommittershipAuthorization
      ### Abilities

      # TODO: Needs more polymorphism
      def can_write_to?(user, repository)
        if repository.wiki?
          can_write_to_wiki?(user, repository)
        else
          committers(repository).include?(user)
        end
      end

      def can_edit_comment?(user, comment)
        comment.creator?(user) && comment.recently_created?
      end

      ### Abilities, in terms of committers, reviewers and administrators
      def can_resolve?(user, merge_request)
        return false unless user.is_a?(User)
        return true if user === merge_request.user
        return reviewers(merge_request.target_repository).include?(user)
      end
      ###

      ### Roles

      ### Roles, in terms of committers, reviewers and administrators
      def committer?(candidate, repository)
        candidate.is_a?(User) ? committers(repository).include?(candidate) : false
      end

      def reviewer?(candidate, repository)
        candidate.is_a?(User) ? reviewers(repository).include?(candidate) : false
      end

      def admin?(candidate, repository)
        candidate.is_a?(User) ? administrators(repository).include?(candidate) : false
      end
      ###

      def site_admin?(user)
        user.is_a?(User) && user.is_admin
      end

      # returns an array of users who have commit bits to this repository either
      # directly through the owner, or "indirectly" through the associated
      # groups
      def committers(repository)
        repository.committerships.committers.map{|c| c.members }.flatten.compact.uniq
      end

      # Returns a list of Users who can review things (as per their Committership)
      def reviewers(repository)
        repository.committerships.reviewers.map{|c| c.members }.flatten.compact.uniq
      end

      # The list of users who can admin this repo, either directly as
      # committerships or indirectly as members of a group
      def administrators(repository)
        repository.committerships.admins.map{|c| c.members }.flatten.compact.uniq
      end

      def review_repositories(user)
        user.committerships.reviewers
      end

      private
      def can_write_to_wiki?(user, repository)
        case repository.wiki_permissions
        when Repository::WIKI_WRITABLE_EVERYONE
          return true
        when Repository::WIKI_WRITABLE_PROJECT_MEMBERS
          return repository.project.member?(user)
        end
      end
    end
  end
end
