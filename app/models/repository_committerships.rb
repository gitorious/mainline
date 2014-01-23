# encoding: utf-8
#--
#   Copyright (C) 2014 Gitorious AS
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

class RepositoryCommitterships
  def initialize(repository)
    @repository = repository
  end

  def find(id)
    all.find(id)
  end

  def new_committership(attrs = {})
    attrs = {repository: repository}.merge(attrs)
    Committership.new(attrs)
  end

  def create_for_owner!(another_owner = owner, creator = nil)
    committership = new_committership
    committership.committer = another_owner
    committership.creator = creator
    committership.permissions = (Committership::CAN_REVIEW |
                                 Committership::CAN_COMMIT |
                                 Committership::CAN_ADMIN)
    committership.save!
    committership
  end

  def create!(attrs)
    create_with_permissions!(attrs, nil)
  end

  def create_with_permissions!(attrs, perms)
    cs = new_committership(attrs)
    cs.permissions = perms
    cs.save!
    cs
  end


  def destroy_for_owner
    existing = all.find_by_committer_id_and_committer_type(owner.id, owner.class.name)
    existing.destroy if existing
  end

  def update_owner(another_owner, creator = nil)
    if cs_to_upgrade = all.detect{|c|c.committer == another_owner}
      cs_to_upgrade.build_permissions(:review, :commit, :admin)
      cs_to_upgrade.save!
    else
      create_for_owner!(another_owner, creator)
    end
  end

  def destroy(id, current_user)
    committership = find(id)

    # Update creator to hold the "destroyer" user account
    # Makes sure hooked-in event reports correct destroying user
    # We have no other way of passing destroying user along
    # except restructing code to not use implicit event hooks.
    committership.creator = current_user
    committership.destroy
  end

  def destroy_all
    all.destroy_all
  end

  def count
    all.count
  end

  def all
    repository._committerships
  end

  def committers
    all.committers.map{|c| c.members }.flatten.compact.uniq
  end

  def reviewers
    all.reviewers.map{|c| c.members }.flatten.compact.uniq
  end

  def administrators
    all.admins.map{|c| c.members }.flatten.compact.uniq
  end

  def admins
    all.select { |c| c.admin? }
  end

  def members
    all.
      includes(:committer).
      map(&:committer).
      flat_map { |committer| committer.is_a?(User) ? committer : committer.members }.
      uniq
  end

  def users
    all.users
  end

  def groups
    all.groups
  end

  def reload
    all.reload
  end

  private

  attr_reader :repository

  def owner
    repository.owner
  end
end

