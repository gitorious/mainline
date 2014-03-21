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
  attr_reader :repository

  def initialize(repository)
    @repository = repository
  end

  def find(id)
    return super_group if super_group?(id) && !super_group_removed?
    raw_all.find(id)
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
    existing = raw_all.find_by_committer_id_and_committer_type(owner.id, owner.class.name)
    existing.destroy if existing
  end

  def update_owner(another_owner, creator = nil)
    if cs_to_upgrade = raw_all.detect{|c|c.committer == another_owner}
      cs_to_upgrade.build_permissions(:review, :commit, :admin)
      cs_to_upgrade.save!
    else
      create_for_owner!(another_owner, creator)
    end
  end

  def destroy(id, current_user)
    return remove_super_group! if super_group?(id)

    committership = find(id)

    Committership.transaction do
      committership.destroy
      committership.add_removed_committer_event(current_user)
    end
  end

  def destroy_all
    raw_all.destroy_all
  end

  def count
    all.count
  end

  def all
    return raw_all unless super_group_available?
    [super_group] + repository._committerships
  end

  def committers
    return User.all if super_group_available?
    raw_all.committers.map{|c| c.members }.flatten.compact.uniq
  end

  def reviewers
    return User.all if super_group_available?
    raw_all.reviewers.map{|c| c.members }.flatten.compact.uniq
  end

  def administrators
    return User.all if super_group_available?
    raw_all.admins.map{|c| c.members }.flatten.compact.uniq
  end

  def last_admin?(committership)
    raw_all.admins == [committership]
  end

  def users
    raw_all.users
  end

  def groups
    return raw_all.groups unless super_group_available?
    [super_group] + raw_all.groups
  end

  def reload
    raw_all.reload
  end

  def add_super_group!
    repository.update_attribute(:super_group_removed, false)
    super_group
  end

  private

  def raw_all
    repository._committerships
  end

  def remove_super_group!
    repository.update_attribute(:super_group_removed, true)
  end

  def super_group_removed?
    repository.super_group_removed?
  end

  def super_group_available?
    super_group_enabled? && !super_group_removed?
  end

  def super_group?(id)
    id == SuperGroup.id && super_group_enabled?
  end

  def super_group_enabled?
    Gitorious::Configuration.get("enable_super_group")
  end

  def super_group
    SuperGroup.super_committership(self)
  end

  def owner
    repository.owner
  end
end

