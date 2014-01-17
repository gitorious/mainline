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
    # Resolve authorization when LDAP backed groups are used
    #
    # The @authorizer instance variable is an object who is able to
    # perform authorization. This behavior is mixed into all
    # controllers, models etc. - and is able to do authorization which
    # is not handled by an LDAP authorization object; ie. direct user
    # access.

    class RepositoryLdapCommitterships
      def initialize(repository)
        @committerships = repository.repository_committerships.all
      end

      def committers
        committerships.committers
      end

      def group_committers
        committerships.committers.select{|c|c.committer_type == "LdapGroup"}.map(&:committer)
      end

      def reviewers
        committerships.reviewers
      end

      def group_reviewers
        committerships.reviewers.select{|c| c.committer_type == "LdapGroup"}.map(&:committer)
      end

      def administrators
        committerships.admins
      end

      def group_administrators
        committerships.admins.select{|c| c.committer_type == "LdapGroup"}.map(&:committer)
      end

      private

      attr_reader :committerships
    end

    class LdapGroupAuthorization
      def initialize(authorizer)
        @authorizer = authorizer
      end

      def push_granted?(repository, user)
        return true if @authorizer.committers(repository).include?(user)
        groups = Team.for_user(user)
        groups_with_access = repository_ldap_committerships(repository).group_committers
        return groups_with_access.any?{|group| groups.include?(group) }
      end

      def can_resolve_merge_request?(user, merge_request)
        repository_committerships = repository_ldap_committerships(merge_request.target_repository)
        return true if repository_committerships.reviewers.any? {|cs| cs.committer == user}

        groups = Team.for_user(user)
        review_groups = repository_committerships.group_reviewers
        return review_groups.any?{|group| groups.include?(group)}
      end

      def repository_admin?(candidate, repository)
        repository_committerships = repository_ldap_committerships(repository)
        return true if repository_committerships.administrators.any? {|cs| cs.committer == candidate}

        groups = Team.for_user(candidate)
        groups_with_admin_access = repository_committerships.group_administrators
        return groups_with_admin_access.any?{|group| groups.include?(group)}
      end

      def project_admin?(user, project)
        return true if !project.owned_by_group? && project.user == user
        Team.for_user(user).include?(project.owner)
      end

      private

      def repository_ldap_committerships(repository)
        RepositoryLdapCommitterships.new(repository)
      end
    end
  end
end
