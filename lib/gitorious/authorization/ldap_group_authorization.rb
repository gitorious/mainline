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
    class LdapGroupAuthorization
      def initialize(authorizer)
        @authorizer = authorizer
      end

      def push_granted?(repository, user)
        return true if @authorizer.committers(repository).include?(user)
        groups = Team.for_user(user)
        groups_with_access = ldap_groups_with_commit_access(repository)
        return groups_with_access.any?{|group| groups.include?(group) }
      end

      def can_resolve_merge_request?(user, merge_request)
        return true if merge_request.target_repository.committerships.reviewers.any? {|cs| cs.committer == user}
        groups = Team.for_user(user)
        review_groups = merge_request.target_repository.committerships.reviewers.select{|c| c.committer_type == "LdapGroup"}.map(&:committer)
        return review_groups.any?{|group| groups.include?(group)}
      end

      def repository_admin?(candidate, repository)
        return true if repository.committerships.admins.any? {|cs| cs.committer == candidate}
        groups = Team.for_user(candidate)
        groups_with_admin_access = repository.committerships.admins.select{|c| c.committer_type == "LdapGroup"}.map(&:committer)
        return groups_with_admin_access.any?{|group| groups.include?(group)}
      end

      def ldap_groups_with_commit_access(repository)
        repository.committerships.committers.select{|c|c.committer_type == "LdapGroup"}.map(&:committer)
      end

      def project_admin?(user, project)
        return true if !project.owned_by_group? && project.user == user
        Team.for_user(user).include?(project.owner)
      end
    end
  end
end
